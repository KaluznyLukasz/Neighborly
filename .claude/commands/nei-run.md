---
description: Build + launch the app on a simulator (no Xcode UI)
argument-hint: [optional simulator name or udid, default "iPhone 16"]
---

Run `make run` (or `make run SIM='<name>'` for a specific simulator — `make sims` lists
them). It calls `scripts/run.sh`: builds via `scripts/build.sh`, boots the simulator,
opens Simulator.app, installs the `.app`, and launches it.

**On a physical iPhone:** `make run-device` (or `make run-device DEVICE='iPhone (Łukasz)'`
— `make devices` lists paired devices). Builds for `iphoneos` with automatic signing,
then installs + launches via `devicectl`. Needs the phone unlocked with Developer Mode on.

After it launches:
- Confirm it's running (`xcrun simctl launch` prints the pid).
- To verify a visual change, `make screenshot` writes `build/screenshot.png` — read it.
- `make logs` streams the app's `os_log`; `make stop` kills it.

If the build fails, fix it before reporting — same rules as `/nei-build`.
