#!/bin/bash
# Builds build/Melatonin.app from the Swift package.
#
#   Scripts/build.sh                     # signed with the best identity on this Mac
#   UNIVERSAL=1 Scripts/build.sh         # Apple silicon + Intel, for releases
#   SIGN_IDENTITY="Developer ID Application: …" Scripts/build.sh
#   Scripts/make-signing-identity.sh     # once per Mac: stable local signing
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
# Sign with SIGN_IDENTITY, else this Mac's Developer ID, else the local
# "Melatonin Self-Signed" identity, else ad hoc. Only a Team ID (Developer ID)
# keeps keychain access across updates; a self-signed identity at least keeps
# Location access; ad hoc signatures change every build.
DEVELOPER_ID="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/"Developer ID Application:/ && !found {print $2; found = 1}')"
LOCAL_IDENTITY="$(security find-identity -p codesigning 2>/dev/null | awk '/"Melatonin Self-Signed"/ && !found {print $2; found = 1}')"
IDENTITY="${SIGN_IDENTITY:-${DEVELOPER_ID:-${LOCAL_IDENTITY:--}}}"
LABEL="io.github.jugol.melatonin.helper"
APP="build/Melatonin.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Library/LaunchServices" "$APP/Contents/Frameworks"

if [[ "${UNIVERSAL:-0}" == 1 ]]; then
    for arch in arm64 x86_64; do
        swift build -c "$CONFIG" --triple "$arch-apple-macosx14.0"
    done
    ARM="$(swift build -c "$CONFIG" --triple arm64-apple-macosx14.0 --show-bin-path)"
    X86="$(swift build -c "$CONFIG" --triple x86_64-apple-macosx14.0 --show-bin-path)"
    lipo -create "$ARM/Melatonin" "$X86/Melatonin" -output "$APP/Contents/MacOS/Melatonin"
    lipo -create "$ARM/MelatoninHelper" "$X86/MelatoninHelper" -output "$APP/Contents/Library/LaunchServices/$LABEL"
    BIN="$ARM" # Sparkle's framework is already universal
else
    swift build -c "$CONFIG"
    BIN="$(swift build -c "$CONFIG" --show-bin-path)"
    cp "$BIN/Melatonin" "$APP/Contents/MacOS/Melatonin"
    cp "$BIN/MelatoninHelper" "$APP/Contents/Library/LaunchServices/$LABEL"
fi
# Sparkle, for updates. Its XPC services are only for sandboxed apps.
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
ditto "$BIN/Sparkle.framework" "$SPARKLE"
rm -rf "$SPARKLE/XPCServices" "$SPARKLE/Versions/B/XPCServices"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/Melatonin"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp "Support/$LABEL.plist" Support/install-helper.sh Support/uninstall-helper.sh "$APP/Contents/Resources/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

SIGN_FLAGS=(--force --options runtime --sign "$IDENTITY")
# Notarization needs a secure timestamp; skip the network round trip for debug builds.
[[ "$IDENTITY" == Developer\ ID* && "$CONFIG" == release ]] && SIGN_FLAGS+=(--timestamp)

codesign "${SIGN_FLAGS[@]}" "$SPARKLE/Versions/B/Autoupdate"
codesign "${SIGN_FLAGS[@]}" "$SPARKLE/Versions/B/Updater.app"
codesign "${SIGN_FLAGS[@]}" "$SPARKLE"
codesign "${SIGN_FLAGS[@]}" --identifier "$LABEL" "$APP/Contents/Library/LaunchServices/$LABEL"
codesign "${SIGN_FLAGS[@]}" --entitlements Support/Melatonin.entitlements "$APP"

echo "Built $APP ($IDENTITY)"
