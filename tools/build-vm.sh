#!/usr/bin/env bash
#
# Builds a trimmed Pharo VM, plus the plugins the VM dlopens at runtime.
#
# Apple platforms get one xcframework slice each; combine them with
# make-xcframework.sh. Elsewhere the manifest resolves a system library, so the
# VM is staged into a DESTDIR tree the way radare2 and frida-core are.
#
#   PLATFORM=macos           tools/build-vm.sh
#   PLATFORM=ios             tools/build-vm.sh
#   PLATFORM=iossimulator    tools/build-vm.sh
#   PLATFORM=linux           tools/build-vm.sh
#   PLATFORM=windows         tools/build-vm.sh

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
		staging="framework"
		;;
	ios)
		architectures="arm64"
		flavour="${FLAVOUR:-StackVM}"
		sysroot="iphoneos"
		staging="framework"
		;;
	iossimulator)
		architectures="arm64"
		flavour="${FLAVOUR:-StackVM}"
		sysroot="iphonesimulator"
		staging="framework"
		;;
	linux)
		architectures="$(uname -m)"
		flavour="${FLAVOUR:-CoInterpreter}"
		sysroot=""
		staging="prefix"
		library_suffix="so"
		host_headers="unix"
		;;
	windows)
		architectures="$(uname -m)"
		flavour="${FLAVOUR:-CoInterpreter}"
		sysroot=""
		staging="prefix"
		library_suffix="dll"
		host_headers="win"
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

# The host installs this tree over its own root, so the paths baked into the
# pkg-config file have to be where it lands rather than where it was staged.
# Setting DESTDIR to nothing installs into PREFIX directly, which is what a
# build from source wants.
PREFIX="${PREFIX:-/usr}"
LIBDIR="${LIBDIR:-${PREFIX}/lib}"
INCLUDEDIR="${INCLUDEDIR:-${PREFIX}/include}"
destdir="${DESTDIR-${output_dir}/destdir/${PLATFORM}-${arch}}"

trimmed_options=(
	-DFEATURE_LIB_SDL2=OFF
	-DFEATURE_LIB_CAIRO=OFF
	-DFEATURE_LIB_FREETYPE2=OFF
	-DFEATURE_LIB_GIT2=OFF
)

# A desktop build makes every plugin by default; a cross build makes only what
# it is asked for. These are the ones the image reaches for -- without them it
# starts without files, without locales and without large integers, which is far
# enough short of an image that the bridge never installs. SqueakSSL is not
# among them: its Mac sources reach for keychain search keys iOS withholds.
ios_plugins=(
	FilePlugin
	NewFilePlugin
	FileAttributesPlugin
	SocketPlugin
	UUIDPlugin
	LocalePlugin
	LargeIntegers
	MiscPrimitivePlugin
	BitBltPlugin
	SurfacePlugin
	FloatArrayPlugin
)

cpu_count() {
	if command -v nproc >/dev/null 2>&1; then
		nproc
	else
		sysctl -n hw.ncpu
	fi
}

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
	perl -ni -e 'print unless m{#import <Cocoa/Cocoa\.h>}' "${checkout_dir}/src/osx/utilsMac.mm"
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

	cmake --build "${generated_dir}" --target generate-sources -j"$(cpu_count)"
}

# The VM asks for its code zone and stack pages at fixed addresses and gives up
# when something already holds them -- in Luma that is JavaScriptCore, whose own
# JIT claims the same range. Neither address is read as a constant anywhere, so
# let them settle wherever mmap put them; not getting a preferred address is not
# an error. The object memory spaces are left alone: their addresses *are* baked
# into the young/old masks and the pointer classification.
relocatable_regions=(codeZone stack)

tolerate_relocated_regions() {
	local generated region
	for generated in "${generated_dir}"/generated/64/vm/src/*interp.c; do
		for region in "${relocatable_regions[@]}"; do
			perl -0pi -e "s/logError\\(\"Could not allocate ${region} in the expected place([^\\n]*)\\n\\s*error\\(\"Error allocating\"\\);\\n/logDebug(\"Could not allocate ${region} in the expected place\$1\\n/" "${generated}"
		done
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
		"${trimmed_options[@]}"
	)
	local targets=()

	if [ "${staging}" = "framework" ]; then
		options+=(-DCMAKE_OSX_ARCHITECTURES="${architectures}")
	fi

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
		for plugin in "${ios_plugins[@]}"; do
			targets+=(--target "${plugin}")
		done
	fi

	cmake -S "${checkout_dir}" -B "${build_dir}" "${options[@]}"
	# bash 3.2 counts an empty array as unbound under set -u.
	cmake --build "${build_dir}" ${targets[@]+"${targets[@]}"} -j"$(cpu_count)"
}

built_libraries_dir() {
	case "${PLATFORM}" in
		macos)
			echo "${build_dir}/build/vm/Debug/Pharo.app/Contents/MacOS/Plugins"
			;;
		ios|iossimulator)
			echo "${build_dir}/build/vm"
			;;
		*)
			dirname "$(find "${build_dir}" -name "libPharoVMCore.${library_suffix}" -print -quit)"
			;;
	esac
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

# Where there is no framework the manifest asks for a system library, so lay the
# core, its plugins and its headers out the way a package manager would.
stage_prefix() {
	rm -rf "${destdir}"
	mkdir -p "${destdir}${LIBDIR}"

	local built
	built="$(built_libraries_dir)"
	cp "${built}"/*."${library_suffix}" "${destdir}${LIBDIR}/"
	if [ "${PLATFORM}" = "windows" ]; then
		cp "${built}"/*.lib "${destdir}${LIBDIR}/"
	fi

	stage_headers_into "${destdir}${INCLUDEDIR}/PharoVM"
	write_pkgconfig
}

# pharo-vm publishes no pkg-config file, and the Linux manifest asks for one by
# name. LSB_FIRST is a compile definition rather than anything config.h records,
# and unix/sqConfig.h refuses to compile without it.
write_pkgconfig() {
	if [ "${PLATFORM}" = "windows" ]; then
		return
	fi

	mkdir -p "${destdir}${LIBDIR}/pkgconfig"
	cat > "${destdir}${LIBDIR}/pkgconfig/pharo-vm.pc" <<-EOF
		includedir=${INCLUDEDIR}
		libdir=${LIBDIR}

		Name: pharo-vm
		Description: Pharo virtual machine core
		Version: ${PHARO_VM_REF}
		Cflags: -I\${includedir} -DLSB_FIRST=1
		Libs: -L\${libdir} -Wl,-rpath,\${libdir} -lPharoVMCore
	EOF
}

# Headers reach for each other both unqualified and via "pharovm/..." paths,
# which the VM's own build answers with a long -I list. Flattening them into one
# directory and dropping the prefixes lets same-directory resolution do it all.
stage_headers_into() {
	local headers="$1"
	local staged="${headers}.tree"

	rm -rf "${headers}" "${staged}"
	mkdir -p "${headers}"
	cp -R "${checkout_dir}/include/pharovm" "${staged}"
	cp "${build_dir}/build/include/pharovm/config.h" "${staged}/"
	cp "${generated_dir}"/generated/64/vm/include/*.h "${staged}/"

	find "${staged}" -name '*.h' \
		-not -path '*/osx/*' -not -path '*/unix/*' -not -path '*/win/*' \
		-exec cp {} "${headers}/" \;
	local platform_headers
	for platform_headers in $(header_directories); do
		cp "${staged}/${platform_headers}"/*.h "${headers}/"
	done
	rm -rf "${staged}"

	perl -pi -e 's|#include\s*"[^"]*/([^"/]+\.h)"|#include "$1"|' "${headers}"/*.h
}

header_directories() {
	if [ "${staging}" = "framework" ]; then
		echo "unix osx"
	else
		echo "${host_headers}"
	fi
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
	if [ "${staging}" = "framework" ]; then
		echo "slice:    ${slice_dir}"
		echo
		echo "Run make-xcframework.sh to combine the staged slices."
	elif [ -n "${destdir}" ]; then
		echo "destdir:  ${destdir}"
		echo
		echo "Copy its contents over ${PREFIX} to install."
	else
		echo "prefix:   ${PREFIX}"
	fi
}

sync_checkout
if [ "${staging}" = "framework" ]; then
	add_ios_support
fi
if [ -n "${sysroot}" ]; then
	build_libffi
fi
generate_sources
tolerate_relocated_regions
configure_and_build
if [ "${staging}" = "framework" ]; then
	stage_framework
else
	stage_prefix
fi
report
