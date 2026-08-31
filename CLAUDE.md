# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open `Neighborly.xcodeproj` in Xcode. Build and run via Xcode (⌘R) targeting a simulator or device.

Dependencies are managed via Swift Package Manager — Xcode resolves them automatically on first open.

## Testing changes

**Rule: after any UI or build-relevant code change, run a real build and confirm `** BUILD SUCCEEDED **` before reporting the work done.** A `swiftc -parse`/`-typecheck` smoke check on individual files is not sufficient — it catches syntax errors but not cross-file type errors, missing imports of project symbols, or SwiftUI view-builder mistakes.

```
scripts/build.sh
```

This wraps `xcodebuild` (targeting `Neighborly` / iphonesimulator / Debug via `Xcode-beta.app` — the only Xcode installed in this environment) and works around several toolchain-level bugs in this specific Xcode-beta build (iOS SDK 27.0) interacting with the project's Firebase SwiftPM graph — none of them are app code issues, and the script handles all of them automatically:
1. `nanopb`'s checkout ships a real file named `build` at its repo root, colliding with Xcode's Explicit Modules `mkdir` at that path — the script removes it after package resolution.
2. This beta's index-while-building support emits a malformed `-index-store-path` argument — the script passes `COMPILER_INDEX_STORE_ENABLE=NO`.
3. SwiftPM writes each package's generated module maps only into that package's own build dir, but a consuming package looks for them under its own build dir — the script pools every generated modulemap across all checkouts and copies the union back into every checkout so cross-package lookups resolve.
4. Without `-derivedDataPath`, the app target's own build products default to `$(SRCROOT)/build` while SwiftPM package products go to DerivedData regardless, so the app's resource-embed phase can't find package resource bundles — the script sets `SYMROOT` to point both at the same place.

Verified working end-to-end from a fully clean `DerivedData`, single pass, no manual retries. If it ever fails on something new, read the script's comments for context on what's already handled, fix forward, and update the script + this section rather than declaring CLI builds broken again.

## Architecture

Early-stage iOS app (SwiftUI + Firebase iOS SDK 12.13.0).

**Entry point:** `NeighborlyApp.swift` — uses `UIApplicationDelegateAdaptor` to wire `AppDelegate` for `FirebaseApp.configure()` at launch.

**Data layer:** Firebase Firestore. Direct `Firestore.firestore()` calls currently live in views; no repository/service layer yet.

**Models:** `Neighborly/Models/` — `NEIOffer.swift` defines `Offer` (Identifiable, Codable). Uses `CLLocationCoordinate2D` computed from stored `latitude`/`longitude` doubles. `id` is optional (assigned by Firestore on write).

**Firebase config:** `GoogleService-Info.plist` in the app target — do not commit changes to this file with real credentials.

## Key Conventions

- Model file prefix: `NEI` (e.g. `NEIOffer.swift` contains `struct Offer`)
- Location stored as raw `Double` lat/lon on the model; `CLLocationCoordinate2D` exposed as computed property
- Comments in Polish (codebase author is Polish-speaking)
