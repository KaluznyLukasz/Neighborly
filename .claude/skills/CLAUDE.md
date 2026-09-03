# Skills — auto-orchestration (read me, then act)

Skills here are **model-invoked**: apply them by scenario, automatically — the user
should NOT have to name them. When the work matches a row below, invoke that skill via
the Skill tool as part of doing the task (chain several when they overlap). Provenance
+ refetch: `SOURCES.tsv` + `/nei-skills-update`.

## Scenario → skill

| When you are… | Auto-apply |
| --- | --- |
| writing / editing / refactoring ANY SwiftUI view | `nei-swiftui-expert-skill` + `nei-swift-accessibility` |
| auditing a view for accessibility (or touching a11y identifiers / VoiceOver) | `nei-swiftui-accessibility-auditor` |
| choosing / converting colors, hex literals, dark-mode/adaptive colors, contrast checks | `nei-colorkit` |
| writing / editing concurrency — `@MainActor`, actors, `async`/`await`, `Sendable`, data races | `nei-swift-concurrency` |
| writing / changing tests (Swift Testing `#expect`/`#require`, XCTest migration) | `nei-swift-testing-expert` |
| touching Firebase Auth, Firestore security rules, tokens/secrets, Keychain, CryptoKit | `nei-swift-security` |
| writing ANY user-facing text — UI copy, labels, alerts, buttons, empty states, error messages | `nei-writing-for-interfaces` |
| writing ANY prose — commit bodies, PR descriptions, ADRs, learnings, README, comments | `nei-stop-slop` (always; strip AI tells) |
| hitting a deprecated / soft-deprecated SwiftUI API | `nei-update-swiftui-apis` |

## Always

- Any user-facing text goes through `nei-stop-slop` — automatically, every time.
- Any SwiftUI view work pairs `nei-swiftui-expert-skill` with `nei-swift-accessibility`.

## Rule

Vendored skills give *general* Swift/Apple guidance; the Neighborly conventions in the
root `CLAUDE.md` (NEI model prefix, raw `Double` lat/lon, Polish comments, native-iOS
components, always build via `scripts/build.sh`) **win** on conflict. Apply the skill's
craft, keep Neighborly's conventions.
