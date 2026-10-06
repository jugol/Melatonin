#!/bin/bash
# Builds a universal release and packages it as a DMG and a zip in dist/, plus
# dist/appcast.xml for Sparkle (publish it as docs/appcast.xml once the GitHub
# release exists).
#
# With a Developer ID identity and a notarytool keychain profile named
# "melatonin" (NOTARY_PROFILE overrides), the app and the DMG are notarized and
# stapled, so they open without Gatekeeper warnings. Set up the profile once:
#   xcrun notarytool store-credentials melatonin --apple-id <id> --team-id <team>
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist)"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Support/Info.plist)"
PROFILE="${NOTARY_PROFILE:-melatonin}"
# The EdDSA key that signs updates. Keep a backup: without it, installed copies
# can't verify (and won't install) new versions.
SPARKLE_KEY="${SPARKLE_KEY:-$HOME/.config/melatonin/sparkle_ed25519}"
NOTES="Support/release-notes/$VERSION.html"
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

if [[ -f "$SPARKLE_KEY" ]]; then
    ENCLOSURE="$(.build/artifacts/sparkle/Sparkle/bin/sign_update --ed-key-file "$SPARKLE_KEY" dist/Melatonin.zip)"
    cat > dist/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Melatonin</title>
    <link>https://jugol.github.io/Melatonin/</link>
    <item>
      <title>Melatonin $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>https://github.com/jugol/Melatonin/releases/tag/v$VERSION</sparkle:fullReleaseNotesLink>
      <description><![CDATA[
$(cat "$NOTES" 2>/dev/null)
      ]]></description>
      <enclosure url="https://github.com/jugol/Melatonin/releases/download/v$VERSION/Melatonin.zip" type="application/octet-stream" $ENCLOSURE/>
    </item>
  </channel>
</rss>
EOF
    [[ -f "$NOTES" ]] || echo "No release notes at $NOTES; the update window will show none."
else
    echo "No Sparkle key at $SPARKLE_KEY; skipping dist/appcast.xml."
fi

if [[ "$NOTARIZE" == 1 ]]; then
    spctl --assess --type execute --verbose build/Melatonin.app
    spctl --assess --type open --context context:primary-signature --verbose dist/Melatonin.dmg
fi

cd dist
shasum -a 256 Melatonin.dmg Melatonin.zip | tee SHA256SUMS.txt
