---
name: sim-no-tap-use-launch-arg-hook
description: simctl can't tap and Simulator.app isn't scriptable here; to screenshot a deep screen, add a temporary UserDefaults launch-arg branch in ContentView
type: howto
area: Tooling (simulator)
---
`xcrun simctl` has no tap/swipe, and AppleScript can't find a "Simulator" process (the sim runs
headless), so a pushed screen like Profile → Settings can't be reached from the CLI.
**How to apply:** temporarily add a branch in `ContentView` that shows the screen when
`UserDefaults.standard.bool(forKey: "NEIDebugX")` is true, build with `make run`, then
`xcrun simctl launch --terminate-running-process booted <bundle id> -NEIDebugX YES` and
`xcrun simctl io booted screenshot build/x.png`. Wait ~9 s after launch or the screenshot catches
the splash. `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large` checks
Dynamic Type. Revert with `git checkout Neighborly/ContentView.swift`. `xcrun` needs
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` outside `make`.
