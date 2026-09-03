# Project skills

Repo-pinned agent skills (checked in → every contributor + agent gets them without
installing plugins). Open "Agent Skills" format: each dir has a `SKILL.md`.

Routing lives in `CLAUDE.md` (scenario → skill). Provenance + refetch: `SOURCES.tsv`
+ `/nei-skills-update`. All MIT-licensed; upstream `LICENSE` kept in each dir.

Vendored 2026-09-03 (via the Framely repo's already-prefixed copies):

| skill | upstream | use |
| --- | --- | --- |
| `nei-swiftui-expert-skill` | AvdLee/SwiftUI-Agent-Skill | SwiftUI state / perf / Liquid Glass — the app is all SwiftUI |
| `nei-update-swiftui-apis` | AvdLee/SwiftUI-Agent-Skill | refresh deprecated SwiftUI APIs (needs Sosumi MCP) |
| `nei-swift-concurrency` | AvdLee/Swift-Concurrency-Agent-Skill | actors, `@MainActor`, Sendable, Swift 6 |
| `nei-swift-testing-expert` | AvdLee/Swift-Testing-Agent-Skill | Swift Testing suites, XCTest migration |
| `nei-swift-accessibility` | PasqualeVittoriosi/swift-accessibility-skill | platform a11y for every SwiftUI view |
| `nei-swiftui-accessibility-auditor` | rgmez/apple-accessibility-skills | patch-ready a11y audit of a view |
| `nei-swift-security` | ivan-magda/swift-security-skill | Keychain, biometrics, CryptoKit, secrets — Firebase auth/rules |
| `nei-colorkit` | SzpakKamil/ColorKit | color conversion, WCAG/APCA contrast, adaptive/dark-mode colors |
| `nei-writing-for-interfaces` | andrewgleave/skills | UI copy — labels, alerts, empty states |
| `nei-stop-slop` | hardikpandya/stop-slop | strip AI writing tells from prose |

`nei-swiftui-expert-skill`, `nei-swift-concurrency`, `nei-swift-testing-expert` replace
the equivalent Claude Code plugins (disabled for this project in `.claude/settings.json`)
so the versions are pinned in-repo.
