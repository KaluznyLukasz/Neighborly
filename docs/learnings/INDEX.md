# Learnings

Accumulated non-obvious facts — gotchas, tuning rationale, constraints. One file per
learning under `docs/learnings/`. Add with `/nei-learn`; promote recurring rules into
`CLAUDE.md` with `/nei-distill`.

<!-- newest first -->
- [firestore-first-snapshot-may-be-cache](firestore-first-snapshot-may-be-cache.md) — a listener's first snapshot is often cached, the server one follows; filter by document timestamps, not snapshot order
- [backgroundtask-builds-scene-before-launch](backgroundtask-builds-scene-before-launch.md) — .backgroundTask on the scene builds StateObjects before didFinishLaunching; FirebaseApp.configure() lives in App.init
- [ios27-sim-provisional-notifications-denied](ios27-sim-provisional-notifications-denied.md) — iOS 27 beta sim: provisional auth reports granted but add() fails as Denied; test reminders on an iOS 26.x sim
- [derived-data-per-checkout](derived-data-per-checkout.md) — each worktree has its own DerivedData (MD5 of project path); use scripts/derived-data.sh, never a Neighborly-* glob; Xcode hashes /private/tmp/x as /tmp/x
- [push-inside-sheet-pin-primary-action](push-inside-sheet-pin-primary-action.md) — view pushed inside a .medium sheet keeps the detent; pin its main button with safeAreaInset, push instead of sheet-on-sheet
- [sim-no-tap-use-launch-arg-hook](sim-no-tap-use-launch-arg-hook.md) — simctl can't tap; screenshot a deep screen via a temporary launch-arg branch in ContentView
- [button-in-list-tints-primary-text-blue](button-in-list-tints-primary-text-blue.md) — any Button label renders .primary/.secondary text in the tint color (List rows included); use Color(.label)/Color(.secondaryLabel)
- [list-row-restyles-label-in-button](list-row-restyles-label-in-button.md) — Label in a Button inside a List row loses its title and stretches; use HStack { Image; Text }
- [list-row-multiple-navigationlinks-fire-all](list-row-multiple-navigationlinks-fire-all.md) — several NavigationLinks in one List row all fire on one tap; use Buttons + .navigationDestination(item:)
- [swipeactions-need-a-list](swipeactions-need-a-list.md) — .swipeActions does nothing in ScrollView/VStack; use a plain List with clear, separator-less rows
- [form-destructive-button-icon-stays-blue](form-destructive-button-icon-stays-blue.md) — destructive Button with systemImage in a Form: title red, icon blue; add .foregroundStyle(.red)
- [section-per-row-breaks-ondelete](section-per-row-breaks-ondelete.md) — one Section per List row kills ForEach.onDelete; use per-row .swipeActions
- [swiftui-views-need-explicit-firebaseauth-import](swiftui-views-need-explicit-firebaseauth-import.md) — new views reading User.uid/displayName need `import FirebaseAuth` (MemberImportVisibility); SourceKit lies, build tells
- [firebase-cli-via-npx-no-global-install](firebase-cli-via-npx-no-global-install.md) — no global firebase CLI here, use npx firebase-tools@latest, cached login usually exists
- [errormessage-needs-an-alert](errormessage-needs-an-alert.md) — setting errorMessage in a ViewModel does nothing unless a View binds it to .alert
- [firestore-composite-index-for-equality-plus-range](firestore-composite-index-for-equality-plus-range.md) — adding a 2nd whereField/order to an existing range query needs a new composite index or it fails at runtime
- [firebase-json-needs-indexes-key](firebase-json-needs-indexes-key.md) — firebase.json needs an "indexes" key or index deploys are a silent no-op
- [sim-location-button-needs-location](sim-location-button-needs-location.md) — map "my location" button is a no-op on sim until a location is simulated + permission granted
