# Neighborly

An iOS app for asking neighbors for help and giving it. You post what you need on a map,
people nearby offer to help, and you both leave a review when it's done.

SwiftUI front end, Firebase back end (Auth + Firestore). No server code of its own.

## Features

- **Map feed.** Posts near you show up as pins, colored by category: Repairs, General
  Help, Food & Groceries, Services and Items.
- **Posts and replies.** Post a request with a title, description, address and optional
  photo. Neighbors tap **Offer to Help**; you accept or decline each one.
- **Activity tab.** Your inbox and the offers you've sent, with a badge for pending
  replies. After accepting, the poster can set a date: a return date for Items, a planned
  day for everything else. Overdue returns get flagged.
- **Chat.** One thread per exchange, open from the first offer to help.
- **Reviews and trust badges.** The poster marks the exchange done, then both sides rate
  each other. Badges such
  as Top Rated, Trusted Neighbor and Active Helper come from public profile data, so
  nobody can fake one by writing to Firestore.
- **Neighborhood alerts.** Short posts for Lost Pet, Lost & Found, Safety, Outage & Works
  or Heads Up. They expire after 48 hours. Neighbors can message the author privately.
- **Search.** Browse by category within a radius you pick in Settings.
- **Saved posts, blocking, profile editing,** light/dark appearance and per-type
  notification toggles.
- **Local notifications** for due dates, new alerts nearby and alert replies. Firestore
  listeners drive them while the app is open; a `BGAppRefreshTask` checks when it's
  closed. There is no push backend.

## Requirements

- macOS with **Xcode-beta** at `/Applications/Xcode-beta.app` (iOS SDK 27). The `Makefile`
  and scripts point `DEVELOPER_DIR` there.
- An iOS Simulator runtime of **iOS 26.2 or later** (the deployment target). `iPhone 17
  Pro` on iOS 27 works. An `iPhone 16` on iOS 26.0 won't install.
- Swift Package Manager resolves dependencies on first build. The main one is
  [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) 12.13.0.
- Optional: Node.js, for deploying Firestore rules with `npx firebase-tools`.

## Getting started

```sh
git clone https://github.com/KaluznyLukasz/Neighborly.git
cd Neighborly
make run          # build, boot a simulator, install, launch
```

`make run` reuses a booted simulator, or boots `iPhone 17 Pro`. Pick another with
`make run SIM='<name>'` (`make sims` lists them).

To run on your own iPhone, pair it with Xcode once, unlock it, turn on Developer Mode,
then:

```sh
make devices
make run-device DEVICE='<device name>'
```

Device builds use automatic signing with team `8L27R45F5T`. Change `DEVELOPMENT_TEAM` in
the project if you sign with your own account.

You can also open `Neighborly.xcodeproj` in Xcode-beta and press ⌘R.

### Make targets

| Command | Does |
| --- | --- |
| `make build` | Compile for the iOS Simulator (`scripts/build.sh`) |
| `make run` | Build, install and launch on a simulator |
| `make run-device` | Build, install and launch on a paired iPhone |
| `make screenshot` | Save the booted simulator screen to `build/screenshot.png` |
| `make logs` | Stream the app's `os_log` output |
| `make stop` | Kill the app on the booted simulator |
| `make sims` / `make devices` | List simulators / paired devices |
| `make clean` | Remove this checkout's build products |
| `make nuke` | Delete this checkout's whole DerivedData |
| `make clean-cache` | Clear the SwiftPM cache and re-resolve packages |
| `make lint` / `make format` | SwiftLint / SwiftFormat, if installed |

### Why `scripts/build.sh`

Plain `xcodebuild` fails on this Xcode-beta with the Firebase package graph. The script
works around four toolchain bugs (a `nanopb` file named `build`, a malformed index-store
flag, generated module maps that packages can't find, and resource bundles landing in
the wrong directory). Each one has a comment in the script. It also gives every git
worktree its own DerivedData, so worktrees build side by side.

A successful build ends with `** BUILD SUCCEEDED **`.

## Firebase

The app talks to the Firebase project `neighborly-d3c33` (see `.firebaserc`) through
`Neighborly/GoogleService-Info.plist`.

To point it at your own project, create an iOS app in the Firebase console with bundle ID
`app.me.kaluzny.lukasz.Neighborly` (or your own), replace `GoogleService-Info.plist`,
and update `.firebaserc`. Enable Email/Password sign-in and Firestore. Don't commit your
own credentials.

### Data

| Collection | Holds |
| --- | --- |
| `users/{uid}` | Profile, rating, review count. Subcollections `favorites` and `blocked` |
| `offers/{id}` | Posts on the map (`Offer` in code) |
| `transactions/{id}` | One neighbor's offer to help with a post, its status and date. Subcollection `messages` |
| `alerts/{id}` | Neighborhood alerts. Subcollection `threads/{viewerId}/messages` |
| `reviews/{id}` | One review per side per exchange |

Photos and avatars live in the documents as base64 strings.

`firestore.rules` and `firestore.indexes.json` hold the security rules and composite
indexes. Deploy them with:

```sh
npx --yes firebase-tools@latest deploy --only firestore --project neighborly-d3c33
```

A query that adds a second filter or sort to a range query needs a new composite index,
or it fails at runtime.

## Project layout

```
Neighborly/
├── NeighborlyApp.swift   App entry, Firebase setup, background refresh
├── ContentView.swift     Splash, auth gate, tab bar (Map, Activity, Profile, Search)
├── Models/               Offer, Transaction, Review, User, NeighborhoodAlert, trust badges
├── Services/             Firestore and Auth access, one service per collection
├── ViewModels/           @Observable state for each screen
├── Views/                Screens by feature, plus shared Components/
└── Utils/                Notifications, caches, colors, user preferences
scripts/                  build, run and DerivedData helpers
docs/learnings/           Non-obvious facts and gotchas, one per file
docs/decisions/           Architecture decision records
TRD.md                    Original technical requirements and roadmap
```

File names start with `NEI`. A file can hold a type without the prefix: `NEIOffer.swift`
defines `struct Offer`.

## Contributing

- `main` is protected. Branch with `git switch -c <type>/<slug>` and open a pull request.
- Run `make build` and check for `** BUILD SUCCEEDED **` before you push.
- Prefer stock iOS components: SF Symbols, system colors, `.alert`, `.swipeActions`,
  standard sheets and navigation.
- Code comments are in Polish.
- Read `docs/learnings/INDEX.md` before touching an area. If you hit something surprising,
  add a learning.
- Record decisions that change how the app is built in `docs/decisions/`.

The repo carries a [Claude Code](https://claude.com/claude-code) setup: `CLAUDE.md`,
project commands in `.claude/commands/` (`/nei-build`, `/nei-run`, `/nei-learn`,
`/nei-new-adr`), vendored skills in `.claude/skills/` and hooks in `.claude/hooks/`.
