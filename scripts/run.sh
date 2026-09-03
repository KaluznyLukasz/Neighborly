#!/bin/bash
# Build Neighborly, then boot a simulator, install the app, and launch it —
# so a change can be exercised without opening Xcode.
#
# Usage: scripts/run.sh [simulator-udid-or-name]
#   no arg  → reuse an already-booted simulator, else boot $NEI_SIM / "iPhone 17 Pro"
#   The simulator runtime must be >= the app's deployment target (currently iOS 26.2).

set -euo pipefail
cd "$(dirname "$0")/.."

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
export DEVELOPER_DIR

BUNDLE_ID="app.me.kaluzny.lukasz.Neighborly"
REQUESTED="${1:-}"

scripts/build.sh

DD="$(ls -d ~/Library/Developer/Xcode/DerivedData/Neighborly-* 2>/dev/null | head -1)"
APP="$DD/Build/Debug-iphonesimulator/Neighborly.app"
[ -d "$APP" ] || { echo "error: built app not found at $APP" >&2; exit 1; }

# Resolve target simulator.
if [ -n "$REQUESTED" ]; then
  SIM="$REQUESTED"
else
  SIM="$(xcrun simctl list devices booted -j 2>/dev/null \
        | python3 -c 'import sys,json; d=json.load(sys.stdin)["devices"]; ids=[x["udid"] for v in d.values() for x in v if x.get("state")=="Booted"]; print(ids[0] if ids else "")')"
  [ -z "$SIM" ] && SIM="${NEI_SIM:-iPhone 17 Pro}"
fi

echo "==> Simulator: $SIM"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b || true
open -a "$DEVELOPER_DIR/Applications/Simulator.app" 2>/dev/null || open -a Simulator 2>/dev/null || true

echo "==> Installing"
xcrun simctl install "$SIM" "$APP"

echo "==> Launching $BUNDLE_ID"
xcrun simctl launch "$SIM" "$BUNDLE_ID"
echo "==> Running. 'make screenshot' to capture, 'make logs' to tail, 'make stop' to kill."
