#!/bin/bash

set -euo pipefail

readonly script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project_directory="$(cd "${script_directory}/.." && pwd)"
readonly output_directory="${project_directory}/build/release"
readonly app_path="${output_directory}/Rinvio.app"
readonly disk_image_path="${output_directory}/Rinvio-macos-universal.dmg"
readonly settings_path="${script_directory}/dmg/settings.py"
readonly background_path="${script_directory}/dmg/background.png"
readonly retina_background_path="${script_directory}/dmg/background@2x.png"
readonly signing_identity="${SIGNING_IDENTITY:?error: SIGNING_IDENTITY is required}"

if [[ ! -d "${app_path}" ]]; then
  echo "error: app to package was not found: ${app_path}" >&2
  exit 1
fi
if [[ ! -f "${settings_path}" || ! -f "${background_path}" || ! -f "${retina_background_path}" ]]; then
  echo "error: DMG layout files are missing" >&2
  exit 1
fi
if ! command -v dmgbuild >/dev/null 2>&1; then
  echo "error: dmgbuild is missing; install Scripts/requirements-dmg.txt" >&2
  exit 1
fi
if [[ "${signing_identity}" != "Developer ID Application:"* ]]; then
  echo "error: signing identity is not a Developer ID Application certificate" >&2
  exit 1
fi

rm -f "${disk_image_path}"
dmgbuild \
  -s "${settings_path}" \
  -D "app_path=${app_path}" \
  -D "background_path=${background_path}" \
  Rinvio \
  "${disk_image_path}"

readonly verification_mount="$(mktemp -d "${TMPDIR:-/tmp}/rinvio-dmg-verification.XXXXXX")"
cleanup_verification_mount() {
  hdiutil detach "${verification_mount}" >/dev/null 2>&1 || true
  rmdir "${verification_mount}" >/dev/null 2>&1 || true
}
trap cleanup_verification_mount EXIT
hdiutil attach \
  -nobrowse \
  -readonly \
  -mountpoint "${verification_mount}" \
  "${disk_image_path}" >/dev/null
codesign --verify --deep --strict --verbose=2 "${verification_mount}/Rinvio.app"
hdiutil detach "${verification_mount}" >/dev/null
rmdir "${verification_mount}"
trap - EXIT

codesign \
  --force \
  --sign "${signing_identity}" \
  --timestamp \
  --verbose \
  "${disk_image_path}"
codesign --verify --verbose=2 "${disk_image_path}"
hdiutil verify "${disk_image_path}"

echo "Packaged ${disk_image_path}"
