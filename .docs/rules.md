# Project Rules & Learnings

Critical lessons from past sessions to avoid repeated friction.

---

## Task Delegation

### Always Use Category Parameter
**Lesson:** When calling `task()`, always provide `category` parameter (e.g., `unspecified-high`, `quick`). The system requires either `category` or `subagent_type`.
**Context:** Forgetting this causes immediate failure with "Invalid arguments: Must provide either category or subagent_type."
**Verify:** Check task call includes `category="..."` before executing.

---

## File Operations

### Moving Modules Breaks Relative Imports
**Lesson:** When moving Nix modules to different directory depths, update all relative `import ../../..` paths accordingly.
**Context:** Moving `modules/programs/zsh/` to `modules/legacy/_/programs/zsh/` broke imports that referenced `../../../../lib`.
**Verify:** After `mv` operations, run `nix flake check` to catch broken imports immediately.

---

## Dendritic Pattern

### import-tree Ignores Paths with `/_`
**Lesson:** Place legacy/non-dendritic modules under paths containing `/_` (e.g., `modules/legacy/_/`) to exclude them from auto-import.
**Context:** import-tree scans directories but skips any path containing `/_` substring.
**Verify:** Confirm `modules/legacy/_/` exists and flake.nix uses `(inputs.import-tree ./modules)`.

---

## Verification

### Never Trust Subagent Success Claims
**Lesson:** Always run verification commands yourself after task completion. Subagents frequently claim success with incomplete/broken work.
**Context:** Automated checks pass but manual code review often reveals logic errors, missing edge cases, or incomplete implementations.
**Verify:** Run `nix flake check` and eval tests after EVERY task completion before proceeding.

---

## Context Management

### Prune Aggressively During Refactors
**Lesson:** Large refactoring generates many tool outputs. Prune context after each wave/phase to avoid hitting limits.
**Context:** Nix evaluation outputs, file reads, and bash commands accumulate quickly during multi-wave refactors.
**Verify:** Use `distill` for key findings and `prune` for noise every 3-4 tasks.
