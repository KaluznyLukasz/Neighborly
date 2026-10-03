---
name: widget-views-render-check-without-xcode
description: widgetFamily is get-only and simctl can't add widgets; render temp copies of the widget views in the app behind a launch arg
type: howto
area: Tooling (widgets)
---
`simctl` can't put a widget on the home screen, and `EnvironmentValues.widgetFamily` has no
setter, so you can't host `NEIUpNextWidgetView` in the app at a chosen size as-is.
**How to apply:** copy the files from `NeighborlyWidgets/` (minus the `@main` bundle) into a
temporary app folder, swap `@Environment(\.widgetFamily) private var family` for
`var family: WidgetFamily = .systemSmall` with `sed`, and show them in a debug view at
170×170 / 364×170 with 16 pt padding and `secondarySystemGroupedBackground`. Gate it with a
launch arg in `ContentView` (see [sim-no-tap-use-launch-arg-hook](sim-no-tap-use-launch-arg-hook.md)),
screenshot light and dark with `xcrun simctl ui booted appearance dark`, then delete the folder.
Inside the app a `Link` tints row text with the accent color, the same thing a `Button` does
([button-in-list-tints-primary-text-blue](button-in-list-tints-primary-text-blue.md)), so the
widget rows set `Color(.label)` themselves. To check the data path, read the snapshot from
`xcrun simctl get_app_container booted app.me.kaluzny.lukasz.Neighborly groups`
→ `Library/Preferences/group.app.me.kaluzny.lukasz.Neighborly.plist`.
