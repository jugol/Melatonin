#!/bin/bash
# Removes Melatonin's privileged helper and puts sleep back to normal.
# Safe to run by hand: sudo bash uninstall-helper.sh
set -uo pipefail

LABEL="io.github.jugol.melatonin.helper"

launchctl bootout "system/$LABEL" 2>/dev/null
rm -f "/Library/PrivilegedHelperTools/$LABEL" "/Library/LaunchDaemons/$LABEL.plist"
rm -rf "/Library/Application Support/Melatonin"
pmset -a disablesleep 0
exit 0
