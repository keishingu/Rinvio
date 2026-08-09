#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
configuration="${1:-debug}"
app_name="QuickDraw PoC.app"
output_root="$project_root/.build/app"
app_bundle="$output_root/$app_name"

swift build \
    --package-path "$project_root" \
    --configuration "$configuration" \
    --product QuickDrawPoC

binary_path="$(swift build --package-path "$project_root" --configuration "$configuration" --show-bin-path)/QuickDrawPoC"

mkdir -p "$app_bundle/Contents/MacOS"
cp "$binary_path" "$app_bundle/Contents/MacOS/QuickDrawPoC"
cp "$project_root/AppResources/Info.plist" "$app_bundle/Contents/Info.plist"

identity="${QUICKDRAW_CODE_SIGN_IDENTITY:--}"
codesign --force --sign "$identity" --identifier dev.actionrouter.quickdraw-poc "$app_bundle"

echo "$app_bundle"
