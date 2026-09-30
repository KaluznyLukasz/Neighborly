# Learnings

Accumulated non-obvious facts — gotchas, tuning rationale, constraints. One file per
learning under `docs/learnings/`. Add with `/nei-learn`; promote recurring rules into
`CLAUDE.md` with `/nei-distill`.

<!-- newest first -->
- [swiftui-views-need-explicit-firebaseauth-import](swiftui-views-need-explicit-firebaseauth-import.md) — new views reading User.uid/displayName need `import FirebaseAuth` (MemberImportVisibility); SourceKit lies, build tells
- [firebase-cli-via-npx-no-global-install](firebase-cli-via-npx-no-global-install.md) — no global firebase CLI here, use npx firebase-tools@latest, cached login usually exists
- [errormessage-needs-an-alert](errormessage-needs-an-alert.md) — setting errorMessage in a ViewModel does nothing unless a View binds it to .alert
- [firestore-composite-index-for-equality-plus-range](firestore-composite-index-for-equality-plus-range.md) — adding a 2nd whereField/order to an existing range query needs a new composite index or it fails at runtime
- [firebase-json-needs-indexes-key](firebase-json-needs-indexes-key.md) — firebase.json needs an "indexes" key or index deploys are a silent no-op
- [sim-location-button-needs-location](sim-location-button-needs-location.md) — map "my location" button is a no-op on sim until a location is simulated + permission granted
