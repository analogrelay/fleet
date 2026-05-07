---
name: jujutsu
description: Consult this skill for non-trivial Jujutsu (jj) version control operations: mid-stack edits, conflict resolution, rebasing, splitting or squashing commits, working with remotes, and recovering from mistakes. Also covers bookmark management and understanding jj log output. Do not use git directly — all VCS operations go through jj.
---

**Never use `git` directly.** All VCS operations use `jj`. See also: `jj-agent-quickref.md` for the everyday commit loop.

---

## Reading `jj log`

```
@  rlvkpnrz user@host 2024-01-10 feat: add parser
○  qpvuntsm user@host 2024-01-10 feat: scaffold
○  zzzzzzzz              (git_head) main@origin
```

- `@` = current working change
- Short IDs (e.g. `rlvkpnrz`) are revision references — use the shortest unambiguous prefix
- `○` = immutable/committed; `@` = mutable working copy
- `~` suffix means a change has conflicts

---

## Navigating the Stack

```sh
jj edit <rev>         # move @ to any revision (safe; descendants stay)
jj edit @-            # move to parent of current
jj new <rev>          # start a new change on top of <rev>
jj next               # move @ to child change
jj prev               # move @ to parent change
```

After `jj edit <rev>`, make changes normally. `jj` tracks them against that revision. Return to tip with `jj edit <tip-rev>` or `jj next`.

---

## Amending / Rewriting

```sh
jj describe -m "new message"          # rewrite description of @
jj squash                             # fold @ into its parent
jj squash --into <rev>                # fold @ into any ancestor
jj squash -i                          # interactive: choose which hunks to squash up
jj unsquash                           # move parent's changes down into @
```

**Fix an earlier commit in a stack:**
```sh
jj edit <broken-rev>   # go back
# ...make fixes...
jj describe -m "updated msg"   # if needed
jj edit <tip-rev>              # return to tip; descendants auto-rebased
```

---

## Splitting a Change

```sh
jj split              # interactive split of @ into two changes
jj split -r <rev>     # split a specific revision
```

Useful when `@` accidentally accumulated multiple concerns.

---

## Rebasing

```sh
jj rebase -d <dest>              # rebase @ onto dest
jj rebase -r <rev> -d <dest>     # rebase a single revision (no descendants)
jj rebase -s <rev> -d <dest>     # rebase <rev> and all descendants
jj rebase -b <bookmark> -d main  # rebase a whole bookmark branch onto main
```

Common case — update a feature stack to latest main:
```sh
jj rebase -s <stack-root-rev> -d main@origin
```

---

## Conflict Resolution

When a rebase or merge creates conflicts, `jj` marks affected files inline and continues (it does not stop mid-operation).

```sh
jj status             # shows conflicted files
jj diff               # shows conflict markers in files
```

Conflict markers look like:
```
<<<<<<< Side #1
code from one side
||||||| Base
original code
======= 
code from other side
>>>>>>> Side #2
```

Resolve manually, then:
```sh
jj resolve            # launch merge tool (if configured)
# or edit files directly, then:
jj describe -m "fix: resolve conflicts"
jj new
```

---

## Abandoning Changes

```sh
jj abandon @          # discard current change, return to parent
jj abandon <rev>      # discard any revision; descendants rebased onto its parent
```

---

## Bookmarks (Branches)

```sh
jj bookmark create <name>          # create at @
jj bookmark create <name> -r <rev> # create at specific rev
jj bookmark set <name>             # move to @
jj bookmark set <name> -r <rev>    # move to specific rev
jj bookmark delete <name>
jj bookmark list
```

Bookmarks do **not** move automatically when you add commits (unlike git branches). After adding commits, run `jj bookmark set <name>` to advance the bookmark.

---

## Working with Git Remotes

```sh
jj git fetch                          # fetch all remotes
jj git fetch --remote origin
jj git push --bookmark <name>         # push a bookmark
jj git push --change @                # push @; auto-creates remote bookmark
jj git push --all                     # push all bookmarks
```

Remote bookmarks appear as `<name>@origin` in `jj log` and are immutable.

---

## Recovering from Mistakes

```sh
jj undo               # undo last operation (structural, not content-based)
jj op log             # full operation history with IDs
jj op restore <op-id> # restore repo to exact state at that operation
```

`jj undo` is safe to call repeatedly. `jj op log` is the escape hatch for anything `undo` can't reach.

---

## Revision Syntax Reference

| Syntax | Meaning |
|---|---|
| `@` | current working copy |
| `@-` | parent of @ |
| `@--` | grandparent of @ |
| `<bookmark>` | tip of a bookmark |
| `main@origin` | remote tracking bookmark |
| `<rev>+` | children of rev |
| `<rev>-` | parents of rev |
| `roots(<set>)` | root revisions of a set |
| `heads(<set>)` | head revisions of a set |

---

## Common Mistake Patterns

**"I made changes in the wrong revision"**
→ `jj move --from @ --to <correct-rev>` or `jj squash --into <rev>`

**"I need to insert a commit in the middle of my stack"**
→ `jj edit <parent-rev>` → `jj new -m "inserted commit"` → make changes → `jj rebase -s <old-child> -d @`

**"My stack has conflicts after a rebase"**
→ `jj log` to find conflicted revisions (`~` marker), `jj edit` each one, resolve files, `jj new` to continue

**"I pushed the wrong thing"**
→ Fix the revision locally, then `jj git push --bookmark <name> --force`
