#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
configuration="${1:-debug}"
if [[ "$configuration" == "debug" ]]; then
    app_name="Rinvio Dev.app"
    display_name="Rinvio Dev"
    bundle_identifier="com.keishingu.rinvio.dev"
else
    app_name="Rinvio.app"
    display_name="Rinvio"
    bundle_identifier="com.keishingu.rinvio"
fi
output_root="$project_root/.build/app"
app_bundle="$output_root/$app_name"

swift build \
    --package-path "$project_root" \
    --configuration "$configuration" \
    --product QuickDrawShortcuts

binary_path="$(swift build --package-path "$project_root" --configuration "$configuration" --show-bin-path)/QuickDrawShortcuts"

mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
cp "$binary_path" "$app_bundle/Contents/MacOS/Rinvio"
cp "$project_root/AppResources/Info.plist" "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "$display_name" "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleName -string "$display_name" "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$bundle_identifier" "$app_bundle/Contents/Info.plist"
cp \
    "$project_root/Sources/QuickDrawCore/Resources/built-in-catalog.json" \
    "$app_bundle/Contents/Resources/built-in-catalog.json"
cp \
    "$project_root/AppResources/PrivacyInfo.xcprivacy" \
    "$app_bundle/Contents/Resources/PrivacyInfo.xcprivacy"
for localization in en ja; do
    mkdir -p "$app_bundle/Contents/Resources/$localization.lproj"
    cp \
        "$project_root/AppResources/$localization.lproj/InfoPlist.strings" \
        "$app_bundle/Contents/Resources/$localization.lproj/InfoPlist.strings"
done

xcrun actool \
    "$project_root/AppResources/Assets.xcassets" \
    --compile "$app_bundle/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 15.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$output_root/asset-info.plist"

if [[ -n "${RINVIO_CODE_SIGN_IDENTITY:-}" ]]; then
    identity="$RINVIO_CODE_SIGN_IDENTITY"
else
    identity="$(
        security find-identity -v -p codesigning 2>/dev/null \
            | sed -n 's/.*"\(Apple Development:[^"]*\)"/\1/p' \
            | head -n 1
    )"
    identity="${identity:--}"
fi

codesign \
    --force \
    --sign "$identity" \
    --identifier "$bundle_identifier" \
    --timestamp=none \
    "$app_bundle"

if [[ "$identity" == "-" ]]; then
    echo "Warning: no Apple Development identity found; using ad-hoc signing." >&2
    echo "Accessibility permission may need to be granted again after rebuilding." >&2
else
    echo "Signed with: $identity" >&2
fi

echo "$app_bundle"
