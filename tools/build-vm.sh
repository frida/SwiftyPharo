#!/usr/bin/env bash
#
# Builds a trimmed Pharo VM and stages one xcframework slice, plus the plugins
# the VM dlopens at runtime. Combine slices with make-xcframework.sh.
#
#   PLATFORM=macos           tools/build-vm.sh
#   PLATFORM=ios             tools/build-vm.sh
#   PLATFORM=iossimulator    tools/build-vm.sh

set -euo pipefail

PHARO_VM_REPO="${PHARO_VM_REPO:-https://github.com/pharo-project/pharo-vm.git}"
PHARO_VM_REF="${PHARO_VM_REF:-pharo-12}"
LIBFFI_REPO="${LIBFFI_REPO:-https://github.com/frida/libffi.git}"
PLATFORM="${PLATFORM:-macos}"
# pharo-vm hardcodes this; a newer libffi warns on every object.
IOS_MINIMUM_VERSION="${IOS_MINIMUM_VERSION:-11.0}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work_dir="${script_dir}/../.build/vm"
checkout_dir="${work_dir}/pharo-vm"
output_dir="${script_dir}/../artifacts"

# iOS withholds writable-executable memory, so no JIT there.
case "${PLATFORM}" in
	macos)
		architectures="${MACOS_ARCHITECTURES:-arm64;x86_64}"
		flavour="${FLAVOUR:-CoInterpreter}"
		sysroot=""
		;;
	ios)
		architectures="arm64"
		flavour="${FLAVOUR:-StackVM}"
		sysroot="iphoneos"
		;;
	iossimulator)
		architectures="arm64"
		flavour="${FLAVOUR:-StackVM}"
		sysroot="iphonesimulator"
		;;
	*)
		echo "unknown PLATFORM: ${PLATFORM}" >&2
		exit 1
		;;
esac

arch="${architectures//;/_}"
build_dir="${checkout_dir}/build-${PLATFORM}-${flavour}"
generated_dir="${checkout_dir}/generate-${flavour}"
slice_dir="${output_dir}/slices/${PLATFORM}-${arch}"
libffi_dir="${work_dir}/libffi"
libffi_prefix="${work_dir}/libffi-${PLATFORM}"

trimmed_options=(
	-DFEATURE_LIB_SDL2=OFF
	-DFEATURE_LIB_CAIRO=OFF
	-DFEATURE_LIB_FREETYPE2=OFF
	-DFEATURE_LIB_GIT2=OFF
)

sync_checkout() {
	if [ -d "${checkout_dir}/.git" ]; then
		git -C "${checkout_dir}" fetch --depth 1 origin "${PHARO_VM_REF}"
		git -C "${checkout_dir}" checkout -q --force FETCH_HEAD
	else
		mkdir -p "$(dirname "${checkout_dir}")"
		git clone -q --depth 1 --branch "${PHARO_VM_REF}" "${PHARO_VM_REPO}" "${checkout_dir}"
	fi
}

add_ios_support() {
	cp "${script_dir}/pharo-vm-ios/iOS.cmake" "${checkout_dir}/cmake/iOS.cmake"

	# Unused — NSBundle is Foundation — and absent on iOS.
	sed -i '' '/#import <Cocoa\/Cocoa.h>/d' "${checkout_dir}/src/osx/utilsMac.mm"
}

# iPhoneOS ships no libffi, and pharo's does not cross-compile.
build_libffi() {
	if [ -d "${libffi_prefix}/lib" ]; then
		return
	fi

	if [ ! -d "${libffi_dir}/.git" ]; then
		git clone -q --depth 1 "${LIBFFI_REPO}" "${libffi_dir}"
	fi

	local cross_file="${work_dir}/libffi-${PLATFORM}.cross"
	write_libffi_cross_file "${cross_file}"

	meson setup "${work_dir}/libffi-build-${PLATFORM}" "${libffi_dir}" \
		--cross-file "${cross_file}" \
		--prefix "${libffi_prefix}" \
		--default-library static \
		--buildtype release \
		--wipe
	meson install -C "${work_dir}/libffi-build-${PLATFORM}"
}

write_libffi_cross_file() {
	local destination="$1"
	local sdk_path
	local minimum_version_flag

	sdk_path="$(xcrun --sdk "${sysroot}" --show-sdk-path)"
	if [ "${PLATFORM}" = "ios" ]; then
		minimum_version_flag="-miphoneos-version-min=${IOS_MINIMUM_VERSION}"
	else
		minimum_version_flag="-mios-simulator-version-min=${IOS_MINIMUM_VERSION}"
	fi

	cat > "${destination}" <<-EOF
		[constants]
		flags = ['-arch', '${arch}', '-isysroot', '${sdk_path}', '${minimum_version_flag}']

		[host_machine]
		# 'ios' matches no branch in libffi, and iOS forbids PROT_EXEC.
		system = 'darwin'
		cpu_family = 'aarch64'
		cpu = 'aarch64'
		endian = 'little'

		[binaries]
		c = 'clang'
		cpp = 'clang++'
		ar = 'ar'
		strip = 'strip'

		[built-in options]
		c_args = flags
		cpp_args = flags
		c_link_args = flags
		cpp_link_args = flags
	EOF
}

# Slang runs a Pharo image, so generate on the host, once per flavour.
generate_sources() {
	if [ -d "${generated_dir}/generated" ]; then
		return
	fi

	cmake -S "${checkout_dir}" -B "${generated_dir}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DFLAVOUR="${flavour}" \
		"${trimmed_options[@]}"

	cmake --build "${generated_dir}" --target generate-sources -j"$(sysctl -n hw.ncpu)"
}

# The VM asks for its code zone at a fixed address and gives up when something
# already holds it -- in Luma that is JavaScriptCore, whose own JIT claims the
# same range. Nothing reads the address as a constant, so let it settle wherever
# mmap put it. macOS gets no MAP_FIXED, so there is nothing else to try.
tolerate_relocated_code_zone() {
	local generated
	for generated in "${generated_dir}"/generated/64/vm/src/*interp.c; do
		perl -0pi -e 's/(logError\("Could not allocate codeZone[^\n]*\n)\s*error\("Error allocating"\);\n/$1/' "${generated}"
	done
}

configure_and_build() {
	local options=(
		-DCMAKE_BUILD_TYPE=Release
		-DFLAVOUR="${flavour}"
		-DPHARO_VM_IN_WORKER_THREAD=ON
		-DPHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES=TRUE
		-DGENERATE_SOURCES=FALSE
		-DGENERATE_VMMAKER=FALSE
		-DGENERATED_SOURCE_DIR="${generated_dir}"
		-DCMAKE_OSX_ARCHITECTURES="${architectures}"
		"${trimmed_options[@]}"
	)
	local targets=()

	if [ -n "${sysroot}" ]; then
		options+=(
			-DCMAKE_SYSTEM_NAME=iOS
			-DCMAKE_SYSTEM_PROCESSOR="${architectures}"
			-DCMAKE_OSX_SYSROOT="${sysroot}"
			-DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_MINIMUM_VERSION}"
			-DFFI_DIR="${libffi_prefix}"
			# Cross-compiling otherwise confines find_* to the sysroot.
			-DCMAKE_FIND_ROOT_PATH="${libffi_prefix}"
			-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH
			-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
		)
		targets=(--target PharoVMCore)
	fi

	cmake -S "${checkout_dir}" -B "${build_dir}" "${options[@]}"
	# bash 3.2 counts an empty array as unbound under set -u.
	cmake --build "${build_dir}" ${targets[@]+"${targets[@]}"} -j"$(sysctl -n hw.ncpu)"
}

built_libraries_dir() {
	if [ -n "${sysroot}" ]; then
		echo "${build_dir}/build/vm"
	else
		echo "${build_dir}/build/vm/Debug/Pharo.app/Contents/MacOS/Plugins"
	fi
}

# A framework keeps the core and its plugins together as one embeddable piece.
stage_framework() {
	rm -rf "${slice_dir}"

	local framework="${slice_dir}/PharoVM.framework"
	local contents="${framework}"
	local binary_subpath=""
	if [ -z "${sysroot}" ]; then
		contents="${framework}/Versions/A"
		binary_subpath="Versions/A/"
	fi
	local install_name="@rpath/PharoVM.framework/${binary_subpath}PharoVM"

	mkdir -p "${contents}"
	cp "$(built_libraries_dir)/libPharoVMCore.dylib" "${contents}/PharoVM"
	install_name_tool -id "${install_name}" "${contents}/PharoVM"

	# ioLoadModule() falls back to dlopen()ing a plugin by leaf name, which dyld
	# resolves through the rpaths of whoever called it. Naming itself lets the
	# core find the plugins sitting beside it wherever the framework is dropped.
	install_name_tool -add_rpath @loader_path "${contents}/PharoVM"
	sign_adhoc "${contents}/PharoVM"

	stage_plugins_into "${contents}" "${install_name}"
	stage_headers_into "${contents}/Headers"
	write_framework_plist "${contents}"

	if [ -z "${sysroot}" ]; then
		ln -s A "${framework}/Versions/Current"
		ln -s Versions/Current/PharoVM "${framework}/PharoVM"
		ln -s Versions/Current/Headers "${framework}/Headers"
		ln -s Versions/Current/Resources "${framework}/Resources"
	fi

	sign_adhoc "${framework}"
}

# The plugins were linked against the core's own name, so point them at the
# framework's binary.
stage_plugins_into() {
	local destination="$1"
	local install_name="$2"
	local plugin

	for plugin in "$(built_libraries_dir)"/*.dylib; do
		case "$(basename "${plugin}")" in
			libPharoVMCore.dylib) continue ;;
		esac

		cp "${plugin}" "${destination}/"
		install_name_tool -change "@rpath/libPharoVMCore.dylib" "${install_name}" \
			"${destination}/$(basename "${plugin}")"
		sign_adhoc "${destination}/$(basename "${plugin}")"
	done
}

# Rewriting load commands invalidates a signature, and a framework will not sign
# while anything nested inside it is unsigned.
sign_adhoc() {
	codesign --force --sign - "$1" 2>/dev/null
}

# Headers reach for each other both unqualified and via "pharovm/..." paths,
# which the VM's own build answers with a long -I list. Flattening them into one
# directory and dropping the prefixes lets same-directory resolution do it all.
stage_headers_into() {
	local headers="$1"
	local staging="${headers}.tree"

	rm -rf "${headers}" "${staging}"
	mkdir -p "${headers}"
	cp -R "${checkout_dir}/include/pharovm" "${staging}"
	cp "${build_dir}/build/include/pharovm/config.h" "${staging}/"
	cp "${generated_dir}"/generated/64/vm/include/*.h "${staging}/"

	rm -rf "${staging}/win"
	find "${staging}" -name '*.h' -not -path '*/osx/*' -not -path '*/unix/*' -exec cp {} "${headers}/" \;
	cp "${staging}/unix"/*.h "${headers}/"
	cp "${staging}/osx"/*.h "${headers}/"
	rm -rf "${staging}"

	sed -i '' -E 's|#include[[:space:]]*"[^"]*/([^"/]+\.h)"|#include "\1"|' "${headers}"/*.h
}

write_framework_plist() {
	local destination="$1"
	local plist="${destination}/Info.plist"

	if [ -z "${sysroot}" ]; then
		mkdir -p "${destination}/Resources"
		plist="${destination}/Resources/Info.plist"
	fi

	cat > "${plist}" <<-EOF
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>CFBundleIdentifier</key><string>re.frida.PharoVM</string>
			<key>CFBundleName</key><string>PharoVM</string>
			<key>CFBundleExecutable</key><string>PharoVM</string>
			<key>CFBundlePackageType</key><string>FMWK</string>
			<key>CFBundleVersion</key><string>1</string>
			<key>CFBundleShortVersionString</key><string>1.0</string>
		</dict>
		</plist>
	EOF
}

report() {
	echo "platform: ${PLATFORM}-${arch} (${flavour})"
	echo "slice:    ${slice_dir}"
	echo
	echo "Run make-xcframework.sh to combine the staged slices."
}

sync_checkout
add_ios_support
if [ -n "${sysroot}" ]; then
	build_libffi
fi
generate_sources
tolerate_relocated_code_zone
configure_and_build
stage_framework
report
