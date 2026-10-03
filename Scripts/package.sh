#!/bin/bash
# Builds a universal release and packages it as a DMG and a zip in dist/.
#
# With a Developer ID identity and a notarytool keychain profile named
# "melatonin" (NOTARY_PROFILE overrides), the app and the DMG are notarized and
# stapled, so they open without Gatekeeper warnings. Set up the profile once:
#   xcrun notarytool store-credentials melatonin --apple-id <id> --team-id <team>
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist)"
PROFILE="${NOTARY_PROFILE:-melatonin}"
UNIVERSAL=1 Scripts/build.sh

IDENTITY="$(codesign -dvv build/Melatonin.app 2>&1 | awk -F= '/^Authority=Developer ID Application/ && !found {print $2; found = 1}')"
NOTARIZE=0
if [[ -n "$IDENTITY" ]] && xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    NOTARIZE=1
else
    echo "Not notarizing (needs a Developer ID signature and the \"$PROFILE\" notarytool profile)."
fi

notarize() {
    xcrun notarytool submit "$1" --keychain-profile "$PROFILE" --wait
}

rm -rf dist
mkdir -p dist/dmg

if [[ "$NOTARIZE" == 1 ]]; then
    ditto -c -k --keepParent build/Melatonin.app dist/notarize.zip
    notarize dist/notarize.zip
    rm dist/notarize.zip
    xcrun stapler staple build/Melatonin.app
fi

cp -R build/Melatonin.app dist/dmg/
ln -s /Applications dist/dmg/Applications
# Unversioned names keep releases/latest/download/Melatonin.dmg stable.
hdiutil create -volname "Melatonin $VERSION" -srcfolder dist/dmg -ov -format UDZO dist/Melatonin.dmg >/dev/null
rm -rf dist/dmg
if [[ "$NOTARIZE" == 1 ]]; then
    codesign --sign "$IDENTITY" --timestamp dist/Melatonin.dmg
    notarize dist/Melatonin.dmg
    xcrun stapler staple dist/Melatonin.dmg
fi
ditto -c -k --keepParent build/Melatonin.app dist/Melatonin.zip

if [[ "$NOTARIZE" == 1 ]]; then
    spctl --assess --type execute --verbose build/Melatonin.app
    spctl --assess --type open --context context:primary-signature --verbose dist/Melatonin.dmg
fi

cd dist
shasum -a 256 Melatonin.dmg Melatonin.zip | tee SHA256SUMS.txt
