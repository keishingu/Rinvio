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

if [[ -n "${QUICKDRAW_CODE_SIGN_IDENTITY:-}" ]]; then
    identity="$QUICKDRAW_CODE_SIGN_IDENTITY"
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
    --identifier dev.actionrouter.quickdraw-poc \
    --timestamp=none \
    "$app_bundle"

if [[ "$identity" == "-" ]]; then
    echo "Warning: no Apple Development identity found; using ad-hoc signing." >&2
    echo "Accessibility permission may need to be granted again after rebuilding." >&2
else
    echo "Signed with: $identity" >&2
fi

echo "$app_bundle"
