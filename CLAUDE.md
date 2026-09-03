# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

No Xcode UI needed. Use `make`:

| command | does |
| --- | --- |
| `make build` | compile for the iOS Simulator (`scripts/build.sh`) |
| `make run` | build + reuse a booted simulator (or boot `iPhone 17 Pro`) + install + launch |
| `make run-device` | build for `iphoneos` + install + launch on a paired iPhone (`DEVICE='iPhone (Łukasz)'` to pick; `make devices` lists them) |
| `make screenshot` | save the booted simulator screen to `build/screenshot.png` |
| `make logs` / `make stop` | stream the app's `os_log` / kill it |
| `make clean` / `make nuke` / `make clean-cache` | build products / all DerivedData / SwiftPM cache |
| `make sims` | list simulators (`make run SIM='<name>'` to pick one) |

The simulator runtime must be ≥ the deployment target (**iOS 26.2**) — a plain
`iPhone 16` on an iOS 26.0 runtime fails to install. `iPhone 17 Pro` (iOS 27) works.
`make run-device` needs the iPhone paired (Xcode opened once), unlocked, Developer Mode
on, and the Mac signed in to the Apple ID for team `8L27R45F5T` (automatic signing).

Xcode still works (⌘R) if preferred. Dependencies are Swift Package Manager — resolved
automatically (`scripts/build.sh` runs `-resolvePackageDependencies` first).

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
- UI should feel native to iOS — favor standard system components and patterns (SF Symbols, `.alert`, `.swipeActions`, system colors/materials, standard navigation/sheet transitions) over custom-styled equivalents, matching how Apple's own apps (Messages, Reminders, Maps, App Store) present lists, detail screens, and confirmations.

## Skills — auto-apply

`.claude/skills/CLAUDE.md` maps scenario → skill. Apply them automatically as part of
doing the work — the user does not have to name them. Key routing:

- Any SwiftUI view work → `nei-swiftui-expert-skill` + `nei-swift-accessibility`.
- Colors / hex / dark-mode / contrast → `nei-colorkit`.
- Firebase Auth, Firestore rules, secrets → `nei-swift-security`.
- Concurrency (`@MainActor`, actors, `async`) → `nei-swift-concurrency`.
- Tests → `nei-swift-testing-expert`.
- Any UI copy → `nei-writing-for-interfaces`. Any prose (commits, PRs, ADRs, comments) →
  `nei-stop-slop` (always, strip AI tells).
- Deprecated SwiftUI API → `nei-update-swiftui-apis`.

Vendored skills give general craft; the conventions above **win** on conflict.

## Knowledge system

- **Learnings** — `docs/learnings/` (`/nei-learn`). One non-obvious fact per file;
  `docs/learnings/INDEX.md` is the index.
- **Decisions** — `docs/decisions/` (ADRs, `/nei-new-adr`).
- **The loop:**
  1. After any UI or build-relevant change, run `scripts/build.sh` and confirm
     `** BUILD SUCCEEDED **` before reporting done.
  2. After a non-obvious fix, `/nei-learn` it.
  3. When a learning recurs or is a project-wide rule, `/nei-distill` it into this file.
  4. Fix what you find in the same change — format drift, a warning, a stale doc, a
     failing test — even if someone else broke it. Don't skip it as "pre-existing".

**Command aliases.** Project commands are `nei-`-prefixed. A bare `/<name>` with no exact
match resolves to `/nei-<name>` (e.g. `/build` → `/nei-build`, `/run` → `/nei-run`,
`/learn` → `/nei-learn`).

**Branching.** Never commit directly to `main` (a hook blocks it) — branch off with
`git switch -c <type>/<slug>`, then open a PR.
