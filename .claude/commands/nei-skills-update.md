---
description: Refetch vendored skills from their upstreams + re-apply the nei- prefix
argument-hint: [optional: specific nei-skill-name(s) to update]
---

Vendored skills live in `.claude/skills/nei-*/`. Provenance is `.claude/skills/SOURCES.tsv`
(columns: nei-name, kind, repo, path, license, commit).

For each vendored skill to update (all, or the ones named in $ARGUMENTS):

1. Read its `SOURCES.tsv` row. Skip `kind=native` (no upstream). Skip `repo=?`.
2. Shallow-clone `https://github.com/<repo>` into a temp dir, `git checkout <commit>`
   (or the latest tag if bumping — then update the SHA in `SOURCES.tsv`).
3. Copy `<path>/` (or the lone `SKILL.md` dir if `path=auto`) over the existing
   `.claude/skills/nei-<name>/`, preserving the local `SOURCE` note.
4. Re-apply the prefix: set frontmatter `name: nei-<name>`; rewrite any internal
   cross-skill path references (e.g. `nei-swiftui-expert-skill/...`).
5. Keep the upstream `LICENSE` file.
6. `git diff` the result and review before committing — upstream changes can shift
   guidance in ways that conflict with this repo's conventions.

Never clone a mutable tip — always check out the pinned commit. Bump deliberately.
