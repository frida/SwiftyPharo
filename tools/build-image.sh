#!/usr/bin/env bash
#
# Loads the SwiftyPharo package into a base Pharo image, producing the image
# embedders boot. Defaults to the VM built by build-vm.sh, which is the only
# one guaranteed to match the image format we ship.
#
#   tools/build-image.sh
#
# LOAD_GROUP=tests additionally loads the package the probe exercises.
# PHARO_CLI and BASE_IMAGE override the VM and the image to start from.

set -euo pipefail

BASE_IMAGE_URL="${BASE_IMAGE_URL:-https://files.pharo.org/image/130/latest-64.zip}"
# The stock image installs its fonts on startup, and refuses to run a command
# when that fails. The shipped image drops the handler; the load still needs it.
FREETYPE_LIB_DIR="${FREETYPE_LIB_DIR:-$(brew --prefix freetype 2>/dev/null)/lib}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_dir="$(cd "${script_dir}/.." && pwd)"
work_dir="${package_dir}/.build/image"
output_dir="${package_dir}/artifacts"
image="${output_dir}/SwiftyPharo.image"
built_vm="${package_dir}/.build/vm/pharo-vm/build-macos-CoInterpreter/build/vm/Debug/Pharo.app/Contents/MacOS/Pharo"

stage_base_image() {
	local base="${BASE_IMAGE:-$(fetch_base_image)}"

	mkdir -p "${output_dir}"
	cp "${base}" "${image}"
	cp "${base%.image}.changes" "${image%.image}.changes"
	cp "$(dirname "${base}")"/*.sources "${output_dir}/" 2>/dev/null || true
}

fetch_base_image() {
	if [ ! -d "${work_dir}/base" ]; then
		mkdir -p "${work_dir}/base"
		curl -sSL "${BASE_IMAGE_URL}" -o "${work_dir}/base.zip"
		unzip -qo "${work_dir}/base.zip" -d "${work_dir}/base"
	fi

	find "${work_dir}/base" -name '*.image' | head -1
}

load_package() {
	local pharo="${PHARO_CLI:-${built_vm}}"

	if [ ! -x "${pharo}" ]; then
		echo "no pharo binary at ${pharo}; run tools/build-vm.sh or set PHARO_CLI" >&2
		exit 1
	fi

	# Metacello reports progress by signalling notifications, so this must not
	# run under a blanket exception handler.
	DYLD_LIBRARY_PATH="${FREETYPE_LIB_DIR}" "${pharo}" --headless "${image}" eval --save "
		Metacello new
			baseline: 'SwiftyPharo';
			repository: 'tonel://${package_dir}/smalltalk/src';
			load: '${LOAD_GROUP:-default}'.
	"

	DYLD_LIBRARY_PATH="${FREETYPE_LIB_DIR}" "${pharo}" --headless "${image}" eval --save \
		"SessionManager default unregisterClassNamed: #FreeTypeSettings" > /dev/null
}

archive_image() {
	(cd "${output_dir}" && zip -qry SwiftyPharo.image.zip SwiftyPharo.image SwiftyPharo.changes)
}

stage_base_image
load_package
archive_image

echo "image:   ${image} ($(du -h "${image}" | cut -f1))"
echo "archive: ${output_dir}/SwiftyPharo.image.zip ($(du -h "${output_dir}/SwiftyPharo.image.zip" | cut -f1))"
