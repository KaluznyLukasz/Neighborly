#!/bin/bash
# Prints this checkout's DerivedData dir (it may not exist yet).
#
# Each checkout of the repo (e.g. a git worktree) gets its own Neighborly-<hash>
# dir. Picking the first `Neighborly-*` would let two checkouts share build
# products. Xcode names the dir after an MD5 of the project path, written as two
# 14-letter base-26 numbers, so compute it the same way. info.plist isn't usable:
# Xcode writes it only on the first build, after package resolution needs the dir.

cd "$(dirname "$0")/.."

suffix="$(python3 - "$PWD/Neighborly.xcodeproj" <<'EOF'
import hashlib, os, sys

def base26(value):
    out = ""
    for _ in range(14):
        out = chr(ord("a") + value % 26) + out
        value //= 26
    return out

# Xcode hashes the standardized path, which drops a leading /private when the
# shorter path exists too (/private/tmp/x → /tmp/x). Without this, a checkout
# under /private/tmp or /private/var gets the wrong dir.
path = sys.argv[1]
if path.startswith("/private/") and os.path.exists(path[len("/private"):]):
    path = path[len("/private"):]

digest = hashlib.md5(path.encode()).digest()
print(base26(int.from_bytes(digest[:8], "big")) + base26(int.from_bytes(digest[8:], "big")))
EOF
)"

echo "$HOME/Library/Developer/Xcode/DerivedData/Neighborly-$suffix"
