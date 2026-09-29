#!/bin/bash
# Installs Melatonin's privileged helper. Run as root by the app (one password
# prompt); takes the path to Melatonin.app as its only argument.
set -euo pipefail

APP="$1"
LABEL="io.github.jugol.melatonin.helper"
HELPER_SRC="$APP/Contents/Library/LaunchServices/$LABEL"
PLIST_SRC="$APP/Contents/Resources/$LABEL.plist"
HELPER_DST="/Library/PrivilegedHelperTools/$LABEL"
PLIST_DST="/Library/LaunchDaemons/$LABEL.plist"

[[ -f "$HELPER_SRC" && -f "$PLIST_SRC" ]] || { echo "Helper files are missing from $APP" >&2; exit 1; }

launchctl bootout "system/$LABEL" 2>/dev/null || true
for _ in $(seq 1 30); do
    launchctl print "system/$LABEL" >/dev/null 2>&1 || break
    sleep 0.1
done

mkdir -p /Library/PrivilegedHelperTools
install -o root -g wheel -m 755 "$HELPER_SRC" "$HELPER_DST"
install -o root -g wheel -m 644 "$PLIST_SRC" "$PLIST_DST"
# The app was already approved when it was opened; don't let a downloaded
# copy's quarantine flag stop launchd from starting the helper.
xattr -d com.apple.quarantine "$HELPER_DST" 2>/dev/null || true
launchctl bootstrap system "$PLIST_DST"
