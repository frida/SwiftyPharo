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
# Left to itself the compiler stamps whichever SDK is installed, and a framework
# asking for a newer macOS than the app does will not load.
MACOS_MINIMUM_VERSION="${MACOS_MINIMUM_VERSION:-11.0}"

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
		;;
	windows)
		architectures="$(uname -m)"
		flavour="${FLAVOUR:-CoInterpreter}"
		sysroot=""
		staging="prefix"
		;;
	*)
		echo "unknown PLATFORM: ${PLATFORM}" >&2
		exit 1
		;;
esac

arch="${architectures//;/_}"
generated_dir="${checkout_dir}/generate-${flavour}"
slice_dir="${output_dir}/slices/${PLATFORM}-${arch}"
libffi_dir="${work_dir}/libffi"
libffi_prefix="${work_dir}/libffi-${PLATFORM}"
meson_build_dir="${checkout_dir}/build-${PLATFORM}-meson"
staged_prefix="${work_dir}/staged-${PLATFORM}"

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

# The Meson build lives here rather than upstream, and wants to sit beside the
# sources it names.
add_meson_build() {
	cp "${script_dir}/pharo-vm-meson/meson.build" \
	   "${script_dir}/pharo-vm-meson/meson.options" "${checkout_dir}/"
	cp "${script_dir}/pharo-vm-meson/config.h.in" "${checkout_dir}/swifty-config.h.in"
}

add_ios_support() {
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

# Slang aside, every platform builds the same way; only the machine file and the
# plugin set differ, and Meson takes both as arguments.
configure_and_build() {
	local architecture="$1"
	local build_dir="${meson_build_dir}-${architecture}"
	local options=(
		--prefix "${PREFIX}"
		--libdir "${LIBDIR#"${PREFIX}"/}"
		--includedir "${INCLUDEDIR#"${PREFIX}"/}"
		--buildtype release
		-Dgenerated_dir="$(basename "${generated_dir}")/generated/64"
		-Dflavour="${flavour}"
	)

	if [ "${staging}" = "framework" ]; then
		local machine_file="${work_dir}/${PLATFORM}-${architecture}.ini"
		write_apple_machine_file "${machine_file}" "${architecture}"
		if [ -n "${sysroot}" ]; then
			options+=(
				--cross-file "${machine_file}"
				-Dios=true
				--pkg-config-path "${libffi_prefix}/lib/pkgconfig"
			)
		else
			options+=(--native-file "${machine_file}")
		fi
	fi

	rm -rf "${build_dir}"
	meson setup "${build_dir}" "${checkout_dir}" "${options[@]}"
	meson compile -C "${build_dir}"
}

# One architecture at a time: clang refuses to preprocess for two at once, which
# is how Meson asks a compiler what headers it has.
write_apple_machine_file() {
	local destination="$1"
	local architecture="$2"
	local flags="'-arch', '${architecture}', "

	: > "${destination}"

	if [ -n "${sysroot}" ]; then
		flags="${flags}'-isysroot', '$(xcrun --sdk "${sysroot}" --show-sdk-path)', "
		if [ "${PLATFORM}" = "ios" ]; then
			flags="${flags}'-miphoneos-version-min=${IOS_MINIMUM_VERSION}'"
		else
			flags="${flags}'-mios-simulator-version-min=${IOS_MINIMUM_VERSION}'"
		fi

		cat > "${destination}" <<-EOF
			[host_machine]
			system = 'darwin'
			subsystem = '${PLATFORM}'
			kernel = 'xnu'
			cpu_family = 'aarch64'
			cpu = 'aarch64'
			endian = 'little'

		EOF
	else
		flags="${flags}'-mmacosx-version-min=${MACOS_MINIMUM_VERSION}'"
	fi

	cat >> "${destination}" <<-EOF
		[binaries]
		c = 'clang'
		cpp = 'clang++'
		objc = 'clang'
		objcpp = 'clang++'
		pkg-config = 'pkg-config'

		[built-in options]
		c_args = [${flags}]
		cpp_args = [${flags}]
		objc_args = [${flags}]
		objcpp_args = [${flags}]
		c_link_args = [${flags}]
		cpp_link_args = [${flags}]
		objc_link_args = [${flags}]
		objcpp_link_args = [${flags}]
	EOF
}

built_libraries_dir() {
	echo "${staged_prefix}${LIBDIR}"
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

# Meson records every library by where it was installed, which inside a framework
# is nowhere. Point each plugin at the framework's own binary and at its siblings
# beside it: one that keeps pointing at the install prefix fails to load, and the
# VM then answers a request for its primitives out of whichever plugin did load.
stage_plugins_into() {
	local destination="$1"
	local install_name="$2"
	local plugin name staged recorded

	for plugin in "$(built_libraries_dir)"/*.dylib; do
		name="$(basename "${plugin}")"
		case "${name}" in
			libPharoVMCore.dylib) continue ;;
		esac

		staged="${destination}/${name}"
		cp "${plugin}" "${staged}"
		install_name_tool -id "@rpath/${name}" "${staged}"

		# Only what this build produced: the install prefix is also where the
		# system keeps libSystem, and pointing that at an rpath is fatal.
		for recorded in $(otool -L "${staged}" | awk -v dir="${LIBDIR}/" \
				'$1 ~ "^" dir { print $1 }'); do
			[ -f "$(built_libraries_dir)/$(basename "${recorded}")" ] || continue

			case "$(basename "${recorded}")" in
				libPharoVMCore.dylib)
					install_name_tool -change "${recorded}" "${install_name}" "${staged}" ;;
				*)
					install_name_tool -change "${recorded}" \
						"@rpath/$(basename "${recorded}")" "${staged}" ;;
			esac
		done

		sign_adhoc "${staged}"
	done
}

# Rewriting load commands invalidates a signature, and a framework will not sign
# while anything nested inside it is unsigned.
sign_adhoc() {
	codesign --force --sign - "$1" 2>/dev/null
}

# Where there is no framework the manifest asks for a system library, which Meson
# lays out and describes for itself -- a generated config header carrying the
# endianness, and a .pc naming only what SwiftPM will accept from one.
# Every architecture is built and installed on its own, then made into the one
# tree the staging reads: a Mac ships several in a single binary.
build_and_stage() {
	local architecture
	local staged=()

	for architecture in ${architectures//;/ }; do
		configure_and_build "${architecture}"
		install_into "${meson_build_dir}-${architecture}" \
			"${work_dir}/staged-${PLATFORM}-${architecture}"
		staged+=("${work_dir}/staged-${PLATFORM}-${architecture}")
	done

	rm -rf "${staged_prefix}"
	cp -R "${staged[0]}" "${staged_prefix}"
	if [ "${#staged[@]}" -gt 1 ]; then
		combine_architectures "${staged[@]}"
	fi
}

combine_architectures() {
	local library name slice
	local inputs=()

	for library in "${staged_prefix}${LIBDIR}"/*.dylib; do
		name="$(basename "${library}")"
		inputs=()
		for slice in "$@"; do
			inputs+=("${slice}${LIBDIR}/${name}")
		done
		lipo -create "${inputs[@]}" -output "${library}"
	done
}

install_into() {
	local build_dir="$1"
	local destination="$2"

	rm -rf "${destination}"
	DESTDIR="${destination}" meson install -C "${build_dir}" --quiet
}

# A framework's headers are flat, and Meson installed them in upstream's own
# layout, so flatten that and drop the directory from the paths they use to
# reach each other. The platform's own headers land last: unix and osx both
# carry an sqConfig.h, and on a framework the Apple one is the one that counts.
stage_headers_into() {
	local headers="$1"
	local installed="${staged_prefix}${INCLUDEDIR}/pharovm"

	rm -rf "${headers}"
	mkdir -p "${headers}"

	find "${installed}" -name '*.h' \
		-not -path '*/win/*' -not -path '*/unix/*' -not -path '*/osx/*' \
		-exec cp {} "${headers}/" \;
	cp "${installed}/unix"/*.h "${headers}/"
	cp "${installed}/osx"/*.h "${headers}/"

	perl -pi -e 's|#include\s*"[^"]*/([^"/]+\.h)"|#include "$1"|' "${headers}"/*.h
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
add_meson_build
add_ios_support
if [ -n "${sysroot}" ]; then
	build_libffi
fi
generate_sources
tolerate_relocated_regions
build_and_stage
if [ "${staging}" = "framework" ]; then
	stage_framework
else
	rm -rf "${destdir}"
	cp -R "${staged_prefix}" "${destdir}"
fi
report
