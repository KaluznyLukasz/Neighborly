#!/bin/bash
# Build Neighborly for a physical iPhone, install it, and launch it — no Xcode UI.
# Requires: the iPhone paired to this Mac (Xcode ran once), unlocked, and Developer
# Mode on; the Mac signed in to the Apple ID for team 8L27R45F5T (automatic signing).
#
# Usage: scripts/run-device.sh [device-name-or-udid]
#   no arg → first connected/paired physical device, or $NEI_DEVICE

set -euo pipefail
cd "$(dirname "$0")/.."

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
export DEVELOPER_DIR

BUNDLE_ID="app.me.kaluzny.lukasz.Neighborly"
REQUESTED="${1:-${NEI_DEVICE:-}}"

# Resolve the target device id from `devicectl`.
if [ -n "$REQUESTED" ]; then
  DEVICE="$(xcrun devicectl list devices 2>/dev/null | awk -v q="$REQUESTED" '
    $0 ~ q { for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-Fa-f-]{36}$/) { print $i; exit } }')"
  [ -z "$DEVICE" ] && DEVICE="$REQUESTED"   # assume the arg is already a udid
else
  DEVICE="$(xcrun devicectl list devices 2>/dev/null | awk '
    /physical/ && (/available/ || /connected/) {
      for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-Fa-f-]{36}$/) { print $i; exit } }')"
fi
[ -z "$DEVICE" ] && { echo "error: no paired physical iPhone found. Connect + unlock it, or pass a udid." >&2; xcrun devicectl list devices; exit 1; }
echo "==> Device: $DEVICE"

NEI_SDK=iphoneos scripts/build.sh

DD="$(ls -d ~/Library/Developer/Xcode/DerivedData/Neighborly-* 2>/dev/null | head -1)"
APP="$DD/Build/Debug-iphoneos/Neighborly.app"
[ -d "$APP" ] || { echo "error: built app not found at $APP" >&2; exit 1; }

echo "==> Installing on device"
xcrun devicectl device install app --device "$DEVICE" "$APP"

echo "==> Launching $BUNDLE_ID"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"
echo "==> Running on device. Check the phone."
