#!/usr/bin/env bash
#
# Loads the SwiftyPharo package into a base Pharo image, producing the image
# embedders boot.
#
#   PHARO_CLI=/path/to/pharo BASE_IMAGE=/path/to/Pharo.image tools/build-image.sh
#
# LOAD_GROUP=tests additionally loads the package the probe exercises.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_dir="$(cd "${script_dir}/.." && pwd)"
output_dir="${package_dir}/artifacts"
image="${output_dir}/SwiftyPharo.image"

stage_base_image() {
	local base="${BASE_IMAGE:?set BASE_IMAGE to a Pharo image}"

	mkdir -p "${output_dir}"
	cp "${base}" "${image}"
	cp "${base%.image}.changes" "${image%.image}.changes"
	cp "$(dirname "${base}")"/*.sources "${output_dir}/" 2>/dev/null || true
}

load_package() {
	local pharo="${PHARO_CLI:?set PHARO_CLI to a headless pharo binary}"

	# Metacello reports progress by signalling notifications, so this must not
	# run under a blanket exception handler.
	"${pharo}" --headless "${image}" eval --save "
		Metacello new
			baseline: 'SwiftyPharo';
			repository: 'tonel://${package_dir}/smalltalk/src';
			load: '${LOAD_GROUP:-default}'.
	"
}

stage_base_image
load_package

echo "image: ${image} ($(du -h "${image}" | cut -f1))"
