---
name: backgroundtask-builds-scene-before-launch
description: Adding .backgroundTask to the App scene makes SwiftUI build the scene before didFinishLaunching; FirebaseApp.configure() must run in App.init
type: gotcha
area: NeighborlyApp
---
After `.backgroundTask(.appRefresh(...))` was added to the `WindowGroup`, the app crashed on
launch with `EXC_BREAKPOINT` inside `Auth.auth()`, called from `NEIAuthService.init()`. SwiftUI
now builds the scene, and with it the `@StateObject` services, before
`AppDelegate.didFinishLaunching` runs. That is where `FirebaseApp.configure()` used to be called.

**Why:** the background task handler has to be registered before launch finishes, so the
scene is set up earlier.
**How to apply:** keep `FirebaseApp.configure()` in `NeighborlyApp.init()`. Anything that
touches Firebase in a `@StateObject` initializer depends on this. A launch crash in `Auth.auth()` /
`Firestore.firestore()` means something ran before `configure()`.
