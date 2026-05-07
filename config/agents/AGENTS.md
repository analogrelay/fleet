# jj (Jujutsu) — Agent Quick Reference

**Never use `git` directly. All VCS operations use `jj`.**
For complex operations (conflict resolution, mid-stack edits, rebasing), consult the `jujutsu` skill.

---

## Mental Model

- Working copy is always a live, auto-tracked change (`@`). No staging area.
- "Committing" = describe `@` + open a new change on top.
- All operations are undoable. When in doubt: `jj undo`.

---

## Core Workflow

```sh
# See state
jj log                        # history; @ is current change
jj diff                       # what's changed in @

# Commit a checkpoint (do this often — after each logical unit of work)
jj describe -m "feat: thing"  # set message on @
jj new                        # seal @ and open next change

# Shorthand: start next change with message already set
jj new -m "feat: next thing"

# Abandon current change (explore/discard)
jj abandon @

# Undo last operation
jj undo
```

---

## Agentic Commit Discipline

Map each plan step to a commit. Never let `@` accumulate across multiple concerns.

```
plan step 1  →  jj new -m "chore: scaffold files"
plan step 2  →  jj new -m "feat: implement X"
plan step 3  →  jj new -m "test: tests for X"
plan step 4  →  jj new -m "fix: edge case"
```

Commit checkpoints are cheap. Prefer more commits over fewer.

---

## Bookmarks (branches)

```sh
jj bookmark create my-feature   # create at @
jj bookmark set my-feature      # move to @
jj git push --bookmark my-feature
```
