#!/bin/bash
# Builds Neighborly for the iOS Simulator via CLI.
#
# Exists to work around toolchain-level bugs in this machine's Xcode-beta
# (iOS SDK 27.0) interacting with the project's Firebase SwiftPM graph — see
# CLAUDE.md "Testing changes" for the full explanation of each workaround
# below. None of these are app code issues.
#
# Usage: scripts/build.sh

set -euo pipefail

cd "$(dirname "$0")/.."

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
export DEVELOPER_DIR

PROJECT="Neighborly.xcodeproj"
TARGET="Neighborly"

echo "==> Resolving Swift Package dependencies"
xcodebuild -resolvePackageDependencies -project "$PROJECT"

DD="$(ls -d ~/Library/Developer/Xcode/DerivedData/Neighborly-* 2>/dev/null | head -1)"
if [ -z "$DD" ]; then
  echo "error: could not locate DerivedData dir for Neighborly after package resolution" >&2
  exit 1
fi

# Workaround 1: nanopb's checkout ships a real file named `build` at its repo
# root, which collides with Xcode's Explicit Modules mkdir at that same path.
NANOPB_BUILD_FILE="$DD/SourcePackages/checkouts/nanopb/build"
if [ -f "$NANOPB_BUILD_FILE" ]; then
  echo "==> Removing blocking nanopb 'build' file"
  rm -f "$NANOPB_BUILD_FILE"
fi

# Workaround 3: SwiftPM's module-map generation writes each package's
# GeneratedModuleMaps-iphonesimulator only into that package's own build
# dir, but the compiler looks for a consuming package's dependencies under
# the CONSUMING package's build dir — cross-package modulemap references
# resolve to the wrong path. Pool every generated modulemap across all
# checkouts and copy the union into every checkout, so any package can find
# any other package's modulemap regardless of which one produced it.
echo "==> Syncing cross-package generated module maps"
CHECKOUTS="$DD/SourcePackages/checkouts"
POOL="$(mktemp -d)"
trap 'rm -rf "$POOL"' EXIT
for d in "$CHECKOUTS"/*/build/GeneratedModuleMaps-iphonesimulator; do
  [ -d "$d" ] && cp -n "$d"/*.modulemap "$POOL"/ 2>/dev/null || true
done
if [ -n "$(ls -A "$POOL" 2>/dev/null)" ]; then
  for c in "$CHECKOUTS"/*/; do
    dst="$c/build/GeneratedModuleMaps-iphonesimulator"
    mkdir -p "$dst"
    cp -n "$POOL"/*.modulemap "$dst"/ 2>/dev/null || true
  done
fi

echo "==> Building"
xcodebuild build \
  -project "$PROJECT" \
  -target "$TARGET" \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  COMPILER_INDEX_STORE_ENABLE=NO \
  SYMROOT="$DD/Build"
# COMPILER_INDEX_STORE_ENABLE=NO: workaround 2 — this beta's index-while-
#   building support emits a malformed -index-store-path argument.
# SYMROOT=...: without -derivedDataPath, xcodebuild defaults the app
#   target's own build products to $(SRCROOT)/build (legacy default) while
#   SwiftPM package products go to DerivedData's standard path regardless —
#   the two never meet, so the app's "Copy Bundle Resources" phase can't
#   find the package resource bundles it needs to embed. Pointing SYMROOT
#   at DerivedData's own Build/ dir puts both in the same place.
