---
description: Build the app for the iOS Simulator and confirm ** BUILD SUCCEEDED **
---

Run `make build` (wraps `scripts/build.sh` — handles the Xcode-beta + Firebase SwiftPM
toolchain workarounds; see the "Testing changes" section of `CLAUDE.md`).

Report honestly:
- On `** BUILD SUCCEEDED **` — say so.
- On failure — show the actual compiler errors (grep `error:`), locate them, fix
  forward. A `swiftc -parse` smoke check is NOT a substitute — only a full build
  catches cross-file type errors and view-builder mistakes.
- Pre-existing break unrelated to the change → say so explicitly, then fix it in the
  same change (don't defer "pre-existing" breakage).

To see the change running, use `/nei-run` instead — it builds then launches on a
simulator. No Xcode UI required for either.
