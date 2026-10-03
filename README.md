<p align="center">
  <img src="Neighborly/Assets.xcassets/NeighborlyIcon.imageset/NeighborlyIcon%201.png" width="128" height="128" alt="Neighborly app icon">
</p>

<h1 align="center">Neighborly</h1>

<p align="center">
  <strong>Ask your neighbors for a hand, or lend one. A native iOS app built in SwiftUI.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2026.2%2B-0A84FF" alt="platform: iOS 26.2+">
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/backend-Firebase-FFCA28?logo=firebase&logoColor=black" alt="backend: Firebase">
  <img src="https://img.shields.io/badge/license-all%20rights%20reserved-8E8E93" alt="license: all rights reserved">
</p>

---

## What is Neighborly

Neighborly puts neighborhood help on a map. Post what you need, like a repair, a dog walk
or groceries, and neighbors nearby offer to help. Pick one, agree on a date, chat, and rate
each other when it's done.

## Features

- 🗺️ **Map feed** — nearby posts as pins, colored by category.
- 🤝 **Offers to help** — neighbors offer, you accept or decline.
- 📅 **Dates and reminders** — return dates for borrowed items, planned days for the rest.
- 💬 **Chat** — one thread per exchange.
- ⭐ **Reviews and trust badges** — both sides rate each other when the job's done.
- 📣 **Neighborhood alerts** — lost pets, safety, outages. Gone after 48 hours.
- 🔍 **Search** — by category, within your radius.
- 🔔 **Notifications** — reminders, nearby alerts and replies, even with the app closed.
- 🧩 **Widgets** — your next agreed dates and the latest alerts nearby, in small and medium.

## Tech

SwiftUI · `@Observable` · MapKit · Firebase Auth + Firestore · local notifications with
`BGAppRefreshTask`.

```sh
make run     # build, boot a simulator, install, launch
make build   # compile only
```

> Requires Xcode-beta (iOS SDK 27). Deployment: iOS 26.2.

---

## 🤖 AI development system

Neighborly ships with a [Claude Code](https://claude.com/claude-code) workflow, so the
codebase **documents and improves itself**:

- **Layered knowledge** — `CLAUDE.md`, learnings in `docs/learnings/`, ADRs in `docs/decisions/`.
- **Guardrails** — hooks block commits to `main` and ask for a build before a session ends.
- **Skills by scenario** — 10 `nei-*` skills (SwiftUI, concurrency, accessibility, security, testing, copy) load **on their own**.
- **The loop** — build → `/nei-learn` the fix → `/nei-distill` it into `CLAUDE.md`.

### Command reference

| Area | Commands |
| --- | --- |
| Build/run | `make build` · `make run` · `make run-device` · `/nei-build` · `/nei-run` |
| Debug | `make logs` · `make screenshot` · `make stop` |
| Clean | `make clean` · `make nuke` · `make clean-cache` |
| Knowledge | `/nei-learn` · `/nei-distill` · `/nei-new-adr` · `/nei-skills-update` |

---

## License

All rights reserved. Vendored skills in `.claude/skills/` keep their own MIT licenses.

---

<p align="center"><sub>Built with SwiftUI · Backed by Firebase · Self-documenting</sub></p>
