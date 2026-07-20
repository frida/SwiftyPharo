#!/usr/bin/env bash
#
# Combines the slices staged by build-vm.sh into PharoVM.xcframework and reports
# the checksum to paste into Package.swift.
#
# Slices are named <platform>-<arch>. An xcframework holds one library per
# platform, so architectures of the same platform are lipo'd together: the two
# macOS builds become a single universal library.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_dir="${script_dir}/../.build/artifacts"
slices_dir="${output_dir}/slices"
universal_dir="${output_dir}/universal"
framework_dir="${output_dir}/PharoVM.xcframework"

platforms() {
	local slice
	for slice in "${slices_dir}"/*/; do
		basename "${slice}" | sed 's/-[^-]*$//'
	done | sort -u
}

fuse_platform() {
	local platform="$1"
	local destination="${universal_dir}/${platform}"
	local libraries=()
	local slice

	for slice in "${slices_dir}/${platform}"-*/; do
		libraries+=("${slice}libPharoVMCore.dylib")
	done

	mkdir -p "${destination}"
	lipo -create "${libraries[@]}" -output "${destination}/libPharoVMCore.dylib"
	cp -R "${slices_dir}/${platform}"-*/Headers "${destination}/"
}

create_framework() {
	local arguments=()
	local platform

	rm -rf "${universal_dir}" "${framework_dir}" "${output_dir}/PharoVM.xcframework.zip"

	for platform in $(platforms); do
		fuse_platform "${platform}"
		arguments+=(
			-library "${universal_dir}/${platform}/libPharoVMCore.dylib"
			-headers "${universal_dir}/${platform}/Headers")
	done

	xcodebuild -create-xcframework "${arguments[@]}" -output "${framework_dir}"

	(cd "${output_dir}" && zip -qry PharoVM.xcframework.zip PharoVM.xcframework)
}

report() {
	local archive="${output_dir}/PharoVM.xcframework.zip"

	echo "slices:      $(ls "${slices_dir}" | tr '\n' ' ')"
	echo "packaged:    $(ls "${framework_dir}" | grep -v Info.plist | tr '\n' ' ')"
	echo "xcframework: ${archive}"
	echo "  size:      $(du -h "${archive}" | cut -f1)"
	echo "  checksum:  $(swift package compute-checksum "${archive}")"
}

create_framework
report
