# Neighborly — dev tasks. No Xcode UI needed.
# Build is a wrapper (scripts/build.sh) that handles the Xcode-beta + Firebase
# SwiftPM toolchain workarounds — see CLAUDE.md "Testing changes".

DEVELOPER_DIR := /Applications/Xcode-beta.app/Contents/Developer
export DEVELOPER_DIR

PROJECT   := Neighborly.xcodeproj
SCHEME    := Neighborly
BUNDLE_ID := app.me.kaluzny.lukasz.Neighborly
SIM       ?=
DEVICE    ?=
DD         = $(shell ls -d ~/Library/Developer/Xcode/DerivedData/Neighborly-* 2>/dev/null | head -1)
APP        = $(DD)/Build/Debug-iphonesimulator/Neighborly.app

.PHONY: help build run run-device screenshot logs stop sims devices clean nuke clean-cache lint format

help:
	@echo "make build        compile for the iOS Simulator (scripts/build.sh)"
	@echo "make run          build + boot sim + install + launch  (reuses booted sim; SIM='iPhone 17 Pro' to pick)"
	@echo "make run-device   build for iphoneos + install + launch on a paired iPhone  (DEVICE='iPhone (Łukasz)' to pick)"
	@echo "make screenshot   save booted-sim screenshot to build/screenshot.png"
	@echo "make logs         stream this app's os_log from the booted sim"
	@echo "make stop         terminate the app on the booted sim"
	@echo "make sims         list available simulators"
	@echo "make devices      list paired physical devices"
	@echo "make clean        remove this project's build products (keeps SPM checkouts)"
	@echo "make nuke         delete this project's entire DerivedData"
	@echo "make clean-cache  clear the SwiftPM cache + re-resolve"
	@echo "make lint         SwiftLint (brew install swiftlint)"
	@echo "make format       SwiftFormat apply (brew install swiftformat)"

build:
	@scripts/build.sh

run:
	@scripts/run.sh "$(SIM)"

run-device:
	@scripts/run-device.sh "$(DEVICE)"

screenshot:
	@mkdir -p build
	@xcrun simctl io booted screenshot build/screenshot.png && echo "wrote build/screenshot.png"

logs:
	@xcrun simctl spawn booted log stream --level debug \
		--predicate 'processImagePath CONTAINS "Neighborly"' --style compact

stop:
	@xcrun simctl terminate booted $(BUNDLE_ID) 2>/dev/null || true

sims:
	@xcrun simctl list devices available | grep -E "iPhone|iPad"

devices:
	@xcrun devicectl list devices | grep -E "physical|Name|----" || echo "no paired devices"

clean:
	@rm -rf "$(DD)/Build" && echo "removed build products"

nuke:
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Neighborly-* && echo "deleted Neighborly DerivedData"

clean-cache:
	@rm -rf ~/Library/Caches/org.swift.swiftpm/repositories \
		~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex 2>/dev/null; \
	xcodebuild -resolvePackageDependencies -project $(PROJECT) | tail -3

lint:
	@command -v swiftlint >/dev/null 2>&1 && swiftlint lint --quiet || echo "swiftlint not installed (brew install swiftlint)"

format:
	@command -v swiftformat >/dev/null 2>&1 && swiftformat . || echo "swiftformat not installed (brew install swiftformat)"
