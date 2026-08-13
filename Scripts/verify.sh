#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_bundle="$project_root/.build/app/QuickDraw Shortcuts.app"

cd "$project_root"

swift format lint --recursive Sources Tests Package.swift
swift test
"$project_root/Scripts/build-app.sh" debug
plutil -lint "$app_bundle/Contents/Info.plist"
test -f "$app_bundle/Contents/Resources/AppIcon.icns"
test -f "$app_bundle/Contents/Resources/Assets.car"
test -f "$app_bundle/Contents/Resources/built-in-catalog.json"
test -f "$app_bundle/Contents/Resources/PrivacyInfo.xcprivacy"
test -f "$app_bundle/Contents/Resources/en.lproj/InfoPlist.strings"
test -f "$app_bundle/Contents/Resources/ja.lproj/InfoPlist.strings"
plutil -lint "$app_bundle/Contents/Resources/PrivacyInfo.xcprivacy"
plutil -lint "$app_bundle/Contents/Resources/en.lproj/InfoPlist.strings"
plutil -lint "$app_bundle/Contents/Resources/ja.lproj/InfoPlist.strings"
plutil -lint "$project_root/AppResources/AppStore-Info.plist"
plutil -lint "$project_root/AppResources/AppStore-ExportOptions.plist"
plutil -lint "$project_root/AppResources/QuickDraw-AppStore.entitlements"
codesign --verify --deep --strict --verbose=2 "$app_bundle"

echo "Verification passed: $app_bundle"
