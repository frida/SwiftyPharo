#!/usr/bin/env bash
#
# Combines the frameworks staged by build-vm.sh into PharoVM.xcframework and
# reports the checksum to paste into Package.swift.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_dir="${script_dir}/../artifacts"
slices_dir="${output_dir}/slices"
framework_dir="${output_dir}/PharoVM.xcframework"

create_xcframework() {
	local arguments=()
	local slice

	for slice in "${slices_dir}"/*/; do
		arguments+=(-framework "${slice}PharoVM.framework")
	done

	rm -rf "${framework_dir}" "${output_dir}/PharoVM.xcframework.zip"
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

create_xcframework
report
