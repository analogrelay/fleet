# Arvee — Memory

This file is maintained collaboratively between you and Arvee.
Arvee proposes changes (additions, edits, or removals) and writes them only after
your explicit approval. You can also edit this file directly at any time.

Entries should be dated so the agent can reason about recency and whether an older
preference has since been superseded.

---

## Reviewer Preferences

<!-- The agent appends or updates dated entries here as it learns your preferences.
     Example format:
     - 2026-03-16: Reviewer does not want style findings on auto-generated files.
     - 2026-03-16: Reviewer wants all public API changes flagged Must-Fix regardless of scope.
-->

---

## Codebase Idioms

<!-- Patterns and conventions specific to repos the reviewer works in.
     The agent adds entries when it notices idioms worth remembering.
     Example format:
     - 2026-03-16 [fleet]: fleetLink is the canonical home-manager pattern for live dotfile
       symlinks. Do not flag its use as unusual.
     - 2026-03-16 [fleet]: alejandra handles all Nix formatting. Never flag whitespace/indent
       differences in .nix files as findings.
-->

---

## Do Not Flag

<!-- Things the reviewer has explicitly said to stop flagging.
     Example format:
     - 2026-03-16: Trailing whitespace in Nix files (formatter handles it).
     - 2026-03-16: Missing JSDoc on internal-only functions in this codebase.
-->

---

## Recurring Patterns to Watch

<!-- High-signal patterns the reviewer wants the agent to actively look for.
     Example format:
     - 2026-03-16: Always check that new Nix modules follow the profiles/roles/realms
       layering pattern; mixing concerns is a Should-Fix.
-->
