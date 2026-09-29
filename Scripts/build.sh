#!/bin/bash
# Builds build/Melatonin.app from the Swift package.
#
#   Scripts/build.sh                     # ad-hoc signed, for local use
#   UNIVERSAL=1 Scripts/build.sh         # Apple silicon + Intel, for releases
#   SIGN_IDENTITY="Developer ID Application: …" Scripts/build.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
IDENTITY="${SIGN_IDENTITY:--}"
LABEL="io.github.jugol.melatonin.helper"
APP="build/Melatonin.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Library/LaunchServices"

if [[ "${UNIVERSAL:-0}" == 1 ]]; then
    for arch in arm64 x86_64; do
        swift build -c "$CONFIG" --triple "$arch-apple-macosx14.0"
    done
    ARM="$(swift build -c "$CONFIG" --triple arm64-apple-macosx14.0 --show-bin-path)"
    X86="$(swift build -c "$CONFIG" --triple x86_64-apple-macosx14.0 --show-bin-path)"
    lipo -create "$ARM/Melatonin" "$X86/Melatonin" -output "$APP/Contents/MacOS/Melatonin"
    lipo -create "$ARM/MelatoninHelper" "$X86/MelatoninHelper" -output "$APP/Contents/Library/LaunchServices/$LABEL"
else
    swift build -c "$CONFIG"
    BIN="$(swift build -c "$CONFIG" --show-bin-path)"
    cp "$BIN/Melatonin" "$APP/Contents/MacOS/Melatonin"
    cp "$BIN/MelatoninHelper" "$APP/Contents/Library/LaunchServices/$LABEL"
fi
cp Support/Info.plist "$APP/Contents/Info.plist"
cp "Support/$LABEL.plist" Support/install-helper.sh Support/uninstall-helper.sh "$APP/Contents/Resources/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

SIGN_FLAGS=(--force --options runtime --sign "$IDENTITY")
[[ "$IDENTITY" != "-" ]] && SIGN_FLAGS+=(--timestamp)

codesign "${SIGN_FLAGS[@]}" --identifier "$LABEL" "$APP/Contents/Library/LaunchServices/$LABEL"
codesign "${SIGN_FLAGS[@]}" "$APP"

echo "Built $APP"
