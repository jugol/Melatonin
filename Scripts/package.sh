#!/bin/bash
# Builds a universal release and packages it as a DMG and a zip in dist/.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist)"
UNIVERSAL=1 Scripts/build.sh

rm -rf dist
mkdir -p dist/dmg
cp -R build/Melatonin.app dist/dmg/
ln -s /Applications dist/dmg/Applications
# Unversioned names keep releases/latest/download/Melatonin.dmg stable.
hdiutil create -volname "Melatonin $VERSION" -srcfolder dist/dmg -ov -format UDZO dist/Melatonin.dmg >/dev/null
rm -rf dist/dmg
ditto -c -k --keepParent build/Melatonin.app dist/Melatonin.zip

cd dist
shasum -a 256 Melatonin.dmg Melatonin.zip | tee SHA256SUMS.txt
