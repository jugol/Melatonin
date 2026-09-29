#!/bin/bash
# Regenerates Resources/AppIcon.icns from Scripts/make-icon.swift.
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"

swift Scripts/make-icon.swift "$WORK/icon.png"
for px in 16 32 128 256 512; do
    sips -z $px $px "$WORK/icon.png" --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
    sips -z $((px * 2)) $((px * 2)) "$WORK/icon.png" --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
cp "$WORK/icon.png" Resources/AppIcon.png
echo "Wrote Resources/AppIcon.icns"
