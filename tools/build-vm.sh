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
output_dir="${script_dir}/../.build/artifacts"

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

stage_slice() {
	rm -rf "${slice_dir}"
	mkdir -p "${slice_dir}/Headers"

	cp "$(built_libraries_dir)/libPharoVMCore.dylib" "${slice_dir}/"
	strip_symbols "${slice_dir}/libPharoVMCore.dylib"
	cp -R "${checkout_dir}/include/pharovm" "${slice_dir}/Headers/"
	cp "${build_dir}/build/include/pharovm/config.h" "${slice_dir}/Headers/pharovm/"
	cp "${generated_dir}"/generated/64/vm/include/*.h "${slice_dir}/Headers/pharovm/"
	flatten_headers
}

# Headers include their siblings unqualified across directories, which the VM's
# own build answers with a long -I list. A flat copy keeps a single one working.
flatten_headers() {
	local headers="${slice_dir}/Headers"

	rm -rf "${headers}/pharovm/win"

	find "${headers}/pharovm" -name '*.h' -not -path '*/osx/*' -not -path '*/unix/*' -exec cp {} "${headers}/" \;
	cp "${headers}/pharovm/unix"/*.h "${headers}/"
	cp "${headers}/pharovm/osx"/*.h "${headers}/"
}

# An xcframework carries one library, so these travel separately.
package_plugins() {
	local staging_dir="${output_dir}/plugin-staging"

	rm -rf "${staging_dir}"
	mkdir -p "${staging_dir}/Plugins"

	cp "$(built_libraries_dir)"/*.dylib "${staging_dir}/Plugins/"
	rm -f "${staging_dir}/Plugins/libPharoVMCore.dylib"

	local plugin
	for plugin in "${staging_dir}/Plugins"/*.dylib; do
		strip_symbols "${plugin}"
	done

	(cd "${staging_dir}" && zip -qry "${output_dir}/PharoVMPlugins-${PLATFORM}-${arch}.zip" Plugins)
	rm -rf "${staging_dir}"
}

# Exported entry points survive; about a sixth of the library goes.
strip_symbols() {
	strip -Sx "$1"
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
configure_and_build
stage_slice
if [ "${PLATFORM}" = "macos" ]; then
	package_plugins
fi
report
