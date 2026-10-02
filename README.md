<p align="center">
  <img src="Neighborly/Assets.xcassets/NeighborlyIcon.imageset/NeighborlyIcon%201.png" width="128" height="128" alt="Neighborly app icon">
</p>

<h1 align="center">Neighborly</h1>

<p align="center">
  <strong>A native iOS app for asking the people next door for a hand, or lending one. Built in SwiftUI on Firebase.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2026.2%2B-0A84FF" alt="platform: iOS 26.2+">
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/UI-SwiftUI-1C1C1E" alt="UI: SwiftUI">
  <img src="https://img.shields.io/badge/backend-Firebase%2012.13-FFCA28?logo=firebase&logoColor=black" alt="backend: Firebase 12.13">
  <img src="https://img.shields.io/badge/version-1.0-3CB371" alt="version 1.0">
  <img src="https://img.shields.io/badge/license-all%20rights%20reserved-8E8E93" alt="license: all rights reserved">
</p>

---

## What is Neighborly

Neighborly is a **map-first** iOS app for local help. You post what you need: a repair, a
dog walk, groceries, a drill to borrow. Neighbors nearby offer to help, you pick one, agree
on a date, chat, and rate each other when it's done.

Four tabs: **Map · Activity · Profile · Search**. Views read `@Observable` view models, and
each view model calls one `NEI*Service` per Firestore collection.

## Features

- 🗺️ **Map feed** — nearby posts as pins, colored by category: Repairs, General Help, Food & Groceries, Services, Items.
- ✍️ **Posts and offers to help** — title, description, address, optional photo. Neighbors tap **Offer to Help**; you accept or decline.
- 📥 **Activity** — your inbox and sent offers, with a badge for pending replies. Set a return date for Items or a planned day for the rest; overdue returns get flagged.
- 💬 **Chat** — one thread per exchange, open from the first offer.
- ⭐ **Reviews and trust badges** — both sides rate each other once the poster marks the job done. Badges (Top Rated, Trusted Neighbor, Active Helper…) come from public data, so nobody can fake one.
- 📣 **Neighborhood alerts** — Lost Pet, Lost & Found, Safety, Outage & Works, Heads Up. They expire after 48 hours; neighbors can message the author privately.
- 🔍 **Search** — browse by category within a radius you set.
- 🔔 **Local notifications** — due dates, new alerts nearby, alert replies. Firestore listeners while open, `BGAppRefreshTask` while closed, no push backend.
- 👤 **Profile and safety** — edit profile, saved posts, blocked users, community guidelines, light/dark appearance.

## Tech

SwiftUI · Swift 5 mode (`MainActor` default isolation, approachable concurrency,
`MemberImportVisibility`) · `@Observable` view models · **MapKit** + **CoreLocation** ·
**Firebase Auth** + **Firestore** via SwiftPM · **UserNotifications** + **BackgroundTasks**.

```sh
make build   # compile for the iOS Simulator (Xcode-beta workarounds built in)
make run     # build + boot a simulator + install + launch
```

> Requires Xcode-beta at `/Applications/Xcode-beta.app` (iOS SDK 27). Deployment: iOS 26.2.
> Use a simulator on iOS 26.2 or later; `iPhone 17 Pro` on iOS 27 works.

`scripts/build.sh` wraps `xcodebuild` and works around four Xcode-beta bugs in the Firebase
package graph. Each fix has a comment in the script. Every git worktree gets its own
DerivedData, so worktrees build side by side.

### Backend

Firebase project `neighborly-d3c33` (`.firebaserc`). Photos and avatars live in the
documents as base64 strings.

| Collection | Holds |
| --- | --- |
| `users/{uid}` | Profile, rating, review count · `favorites`, `blocked` |
| `offers/{id}` | Posts on the map (`Offer` in code) |
| `transactions/{id}` | An offer to help with a post, its status and date · `messages` |
| `alerts/{id}` | Neighborhood alerts · `threads/{viewerId}/messages` |
| `reviews/{id}` | One review per side per exchange |

Rules and indexes live in `firestore.rules` and `firestore.indexes.json`:

```sh
npx --yes firebase-tools@latest deploy --only firestore --project neighborly-d3c33
```

---

## 🤖 Self-improving AI development system

Neighborly ships with a [Claude Code](https://claude.com/claude-code) workflow, so the
codebase **documents and improves itself**:

- **Layered knowledge** — root `CLAUDE.md`, a skill map in `.claude/skills/CLAUDE.md`, one-fact learnings in `docs/learnings/` (`INDEX.md`) and ADRs in `docs/decisions/`.
- **Guardrails** — Claude Code hooks block commits, merges and pushes to `main`, ask for a build and a `/nei-learn` when Swift files changed, and warn before the context window fills up.
- **Auto-applied skills** — 10 vendored `nei-*` skills (SwiftUI, concurrency, accessibility, security, testing, UI copy, prose…) applied **by scenario**, not by hand.
- **The loop** — build until `** BUILD SUCCEEDED **` → `/nei-learn` the non-obvious fix → `/nei-distill` recurring ones into `CLAUDE.md` → fix what you find in the same change.

### Command reference

| Area | Commands |
| --- | --- |
| Build/run | `make build` · `make run` · `make run-device` · `/nei-build` · `/nei-run` |
| Simulator | `make screenshot` · `make logs` · `make stop` · `make sims` · `make devices` |
| Clean | `make clean` · `make nuke` · `make clean-cache` |
| Quality | `make lint` · `make format` (SwiftLint / SwiftFormat, if installed) |
| Knowledge | `/nei-learn` · `/nei-distill` · `/nei-new-adr` · `/nei-skills-update` |

### Setup

```sh
git clone https://github.com/KaluznyLukasz/Neighborly.git
cd Neighborly
make run                                  # SIM='<name>' to pick a simulator
make run-device DEVICE='<device name>'    # paired iPhone, Developer Mode on
```

Device builds sign automatically with team `8L27R45F5T`; change `DEVELOPMENT_TEAM` to use
your own. To run against your own Firebase project, replace
`Neighborly/GoogleService-Info.plist`, update `.firebaserc`, and enable Email/Password
sign-in and Firestore. Don't commit your credentials.

Branch off `main` (`git switch -c <type>/<slug>`) and open a pull request. Code comments
are in Polish.

---

## License

Neighborly has no license file, so default copyright applies: **all rights reserved**.
Vendored skills in `.claude/skills/` keep their own MIT licenses (see `SOURCES.tsv`), and the
Firebase SDK keeps Apache 2.0.

---

<p align="center"><sub>Built with SwiftUI · Backed by Firebase · Self-documenting</sub></p>
