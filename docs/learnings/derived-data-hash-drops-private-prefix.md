---
name: derived-data-hash-drops-private-prefix
description: Xcode hashes /private/tmp/... as /tmp/... when naming the DerivedData dir, so derived-data.sh must strip /private too
type: gotcha
area: build
---

`scripts/build.sh` failed in a worktree under the session scratchpad with `error: no package checkouts in .../DerivedData/Neighborly-bfaiu... after package resolution`. Package resolution had worked, but `xcodebuild` wrote the checkouts to `Neighborly-fnlap...`. `derived-data.sh` hashed `/private/tmp/.../Neighborly.xcodeproj`. Xcode standardizes the path first and drops the `/private` prefix, so it hashed `/tmp/.../Neighborly.xcodeproj`.

**Why:** macOS links `/tmp`, `/var` and `/etc` to `/private/...`. Shells and `$PWD` report the `/private` form, while Foundation's path standardization removes it.

**How to apply:** if the script's DerivedData dir and the one `xcodebuild` created ever disagree, check the path the hash ran on before suspecting package resolution. `derived-data.sh` strips `/private` when the shorter path resolves to the same place.
