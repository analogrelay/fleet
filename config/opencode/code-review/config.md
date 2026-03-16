# Code Review Agent — Configuration

This file contains static tunable knobs. Edit it manually to adjust the agent's behavior.
The agent reads this at the start of every session but never modifies it.

---

## Mode

# Controls whether the agent asks which mode to use at startup, or assumes one.
# Options: ask | conversational | fast
# 'ask' is recommended: the agent prompts you at invocation time.
default_mode: ask

---

## Base Branch Strategy

# How the agent determines what to diff against in branch mode (no PR given).
# 'auto': walks commit parents looking for a branch named 'main' or matching 'release/...'
#         Uses git merge-base to find the exact divergence point.
#         Asks for confirmation if the base is ambiguous.
# 'always-ask': always prompt the user to specify the base ref explicitly.
base_strategy: auto

---

## Finding Categories

# Set any category to 'disabled' to suppress that entire class of findings.
# The agent will still notice issues in disabled categories but won't report them.
security: enabled
correctness: enabled
performance: enabled
tests: enabled
style: enabled
documentation: enabled

---

## Praise

# Maximum number of Praise items allowed in a single review.
# The agent is already instructed to be very selective with praise;
# this is an additional hard cap.
max_praise: 2

---

## Verbosity

# Controls how much the agent explains its reasoning during the conversational pass.
# quiet:   Minimal commentary; just asks questions when needed.
# normal:  Shares key observations as it explores.
# verbose: Thinks out loud throughout the entire exploration.
verbosity: normal
