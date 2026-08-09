#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_bundle="$project_root/.build/app/QuickDraw PoC.app"

cd "$project_root"

swift format lint --recursive Sources Tests Package.swift
swift test
"$project_root/Scripts/build-app.sh" debug
plutil -lint "$app_bundle/Contents/Info.plist"
test -f "$app_bundle/Contents/Resources/AppIcon.icns"
test -f "$app_bundle/Contents/Resources/Assets.car"
codesign --verify --deep --strict --verbose=2 "$app_bundle"

echo "Verification passed: $app_bundle"
