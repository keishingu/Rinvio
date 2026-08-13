#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
archive_root="$(mktemp -d "${TMPDIR:-/tmp}/quickdraw-app-store.XXXXXX")"
archive_path="$archive_root/QuickDrawShortcuts.xcarchive"
derived_data_path="$archive_root/DerivedData"
app_bundle="$archive_path/Products/Applications/QuickDraw Shortcuts.app"

cleanup() {
    rm -rf "$archive_root"
}
trap cleanup EXIT

cd "$project_root"

plutil -lint AppResources/AppStore-Info.plist
plutil -lint AppResources/QuickDraw-AppStore.entitlements
plutil -lint AppResources/PrivacyInfo.xcprivacy
plutil -lint AppResources/en.lproj/InfoPlist.strings
plutil -lint AppResources/ja.lproj/InfoPlist.strings

test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' AppResources/QuickDraw-AppStore.entitlements)" = "true"
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.automation.apple-events' AppResources/QuickDraw-AppStore.entitlements)" = "true"
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.temporary-exception.apple-events:0' AppResources/QuickDraw-AppStore.entitlements)" = "com.google.Chrome"
test "$(plutil -extract NSPrivacyTracking raw AppResources/PrivacyInfo.xcprivacy)" = "false"
test "$(plutil -extract NSPrivacyCollectedDataTypes raw AppResources/PrivacyInfo.xcprivacy)" = "0"

xcodebuild \
    -project QuickDraw.xcodeproj \
    -scheme QuickDraw \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$archive_path" \
    -derivedDataPath "$derived_data_path" \
    -quiet \
    CODE_SIGNING_ALLOWED=NO \
    archive

test -d "$app_bundle"
test "$(plutil -extract CFBundleDisplayName raw "$app_bundle/Contents/Info.plist")" = "QuickDraw Shortcuts"
test "$(plutil -extract CFBundleIdentifier raw "$app_bundle/Contents/Info.plist")" = "com.keishingu.quickdraw-shortcuts"
test "$(plutil -extract LSApplicationCategoryType raw "$app_bundle/Contents/Info.plist")" = "public.app-category.utilities"
test -f "$app_bundle/Contents/Resources/PrivacyInfo.xcprivacy"
test -f "$app_bundle/Contents/Resources/en.lproj/InfoPlist.strings"
test -f "$app_bundle/Contents/Resources/ja.lproj/InfoPlist.strings"
if xattr -p com.apple.quarantine "$app_bundle" >/dev/null 2>&1; then
    echo "Unexpected quarantine attribute in archived app" >&2
    exit 1
fi

architectures="$(lipo -archs "$app_bundle/Contents/MacOS/QuickDraw Shortcuts")"
[[ " $architectures " == *" arm64 "* ]]
[[ " $architectures " == *" x86_64 "* ]]

echo "App Store archive verification passed: QuickDraw Shortcuts ($architectures)"
