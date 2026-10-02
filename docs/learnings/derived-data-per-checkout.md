---
name: derived-data-per-checkout
description: Each checkout or worktree has its own DerivedData dir named after an MD5 of the project path; scripts/derived-data.sh finds the right one
type: gotcha
area: Tooling (scripts, Makefile)
---
The scripts and Makefile used `ls -d DerivedData/Neighborly-* | head -1`. With a second checkout
(a git worktree, e.g. two Claude sessions working in parallel), that picks the other checkout's
dir. Builds then share products, and `make nuke` deleted both.

**Why:** Xcode names the dir `Neighborly-<hash>`, where the hash is the MD5 of the `.xcodeproj`
path written as two 14-letter base-26 numbers. `info.plist` with `WorkspacePath` only appears
after the first build, which is too late for package resolution.
**How to apply:** use `scripts/derived-data.sh` (it computes the hash) wherever a script needs
DerivedData. Don't add new `Neighborly-*` globs.

**`/private` paths:** Xcode hashes the standardized path, so a checkout at
`/private/tmp/x` hashes as `/tmp/x`. Before the script stripped the prefix, a worktree in the
session scratchpad (`/private/tmp/...`) failed with "no package checkouts in ... after package
resolution": Xcode had put them in the `/tmp/...` dir.
