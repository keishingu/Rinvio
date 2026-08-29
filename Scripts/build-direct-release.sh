#!/bin/bash

set -euo pipefail

readonly script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project_directory="$(cd "${script_directory}/.." && pwd)"
readonly output_directory="${project_directory}/build/release"
readonly app_path="${output_directory}/Rinvio.app"
readonly build_number="${BUILD_NUMBER:?error: BUILD_NUMBER is required}"
readonly signing_identity="${SIGNING_IDENTITY:?error: SIGNING_IDENTITY is required}"
readonly marketing_version="${MARKETING_VERSION:-1.0.0}"

if [[ "${signing_identity}" != "Developer ID Application:"* ]]; then
  echo "error: signing identity is not a Developer ID Application certificate" >&2
  exit 1
fi
if [[ ! "${build_number}" =~ ^[0-9]+$ ]]; then
  echo "error: BUILD_NUMBER must contain digits only" >&2
  exit 1
fi
if [[ ! "${marketing_version}" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "error: MARKETING_VERSION must use numeric dot notation" >&2
  exit 1
fi

rm -rf "${output_directory}"
mkdir -p \
  "${app_path}/Contents/MacOS" \
  "${app_path}/Contents/Resources"

build_architecture() {
  local architecture="$1"
  local triple="${architecture}-apple-macosx15.0"
  local scratch_path="${output_directory}/${architecture}"

  swift build \
    --package-path "${project_directory}" \
    --configuration release \
    --scratch-path "${scratch_path}" \
    --triple "${triple}" \
    --product QuickDrawShortcuts

  swift build \
    --package-path "${project_directory}" \
    --configuration release \
    --scratch-path "${scratch_path}" \
    --triple "${triple}" \
    --show-bin-path
}

arm64_bin_path="$(build_architecture arm64 | tail -n 1)"
x86_64_bin_path="$(build_architecture x86_64 | tail -n 1)"

lipo -create \
  "${arm64_bin_path}/QuickDrawShortcuts" \
  "${x86_64_bin_path}/QuickDrawShortcuts" \
  -output "${app_path}/Contents/MacOS/Rinvio"

cp "${project_directory}/AppResources/Info.plist" "${app_path}/Contents/Info.plist"
cp \
  "${project_directory}/Sources/QuickDrawCore/Resources/built-in-catalog.json" \
  "${app_path}/Contents/Resources/built-in-catalog.json"
cp \
  "${project_directory}/AppResources/PrivacyInfo.xcprivacy" \
  "${app_path}/Contents/Resources/PrivacyInfo.xcprivacy"
for localization in en ja; do
  mkdir -p "${app_path}/Contents/Resources/${localization}.lproj"
  cp \
    "${project_directory}/AppResources/${localization}.lproj/InfoPlist.strings" \
    "${app_path}/Contents/Resources/${localization}.lproj/InfoPlist.strings"
done

plutil -replace CFBundleShortVersionString \
  -string "${marketing_version}" \
  "${app_path}/Contents/Info.plist"
plutil -replace CFBundleVersion \
  -string "${build_number}" \
  "${app_path}/Contents/Info.plist"

xcrun actool \
  "${project_directory}/AppResources/Assets.xcassets" \
  --compile "${app_path}/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 15.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "${output_directory}/asset-info.plist"

if [[ ! -f "${app_path}/Contents/Resources/AppIcon.icns" ]]; then
  echo "error: AppIcon was not included in the release app" >&2
  exit 1
fi

readonly executable_path="${app_path}/Contents/MacOS/Rinvio"
readonly architectures="$(lipo -archs "${executable_path}")"
if [[ " ${architectures} " != *" arm64 "* || " ${architectures} " != *" x86_64 "* ]]; then
  echo "error: release executable is not Universal: ${architectures}" >&2
  exit 1
fi

codesign \
  --force \
  --sign "${signing_identity}" \
  --identifier com.keishingu.rinvio \
  --options runtime \
  --entitlements "${project_directory}/AppResources/Rinvio-Direct.entitlements" \
  --timestamp \
  --verbose \
  "${app_path}"
codesign --verify --deep --strict --verbose=2 "${app_path}"
codesign --display --verbose=4 "${app_path}"
readonly signed_entitlements="${output_directory}/signed-entitlements.plist"
codesign --display --entitlements - --xml "${app_path}" > "${signed_entitlements}"
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.automation.apple-events' "${signed_entitlements}")" != "true" ]]; then
  echo "error: signed app is missing the Apple Events entitlement" >&2
  exit 1
fi

"${script_directory}/package-direct-release.sh"

echo "Created ${output_directory}/Rinvio-macos-universal.dmg"
echo "Architectures: ${architectures}"
echo "Signing identity: ${signing_identity}"
