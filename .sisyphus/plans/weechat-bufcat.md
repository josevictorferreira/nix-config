# WeeChat buflist categories (bufcat)

## TL;DR
> **Summary**: Add a WeeChat Python script that categorizes buffers by substring matches, groups/sorts buflist via per-buffer localvars, and prepends a per-category prefix in buflist display (no header lines).
> **Deliverables**: `bufcat.py` script + JSON config schema + Nix packaging to install + automated tests (no WeeChat runtime required).
> **Effort**: Medium
> **Parallel**: YES — 3 waves
> **Critical Path**: Define config+matching → implement script (localvars + buflist patch/restore) → Nix integration → tests + flake check

## Context
### Original Request
- WeeChat Python script to organize buflist into categories via substring matches on buffer/chat name.
- Per-category display prefix (e.g., two leading spaces).
- Default category for uncategorized.
- Replace stock buflist behavior (use built-in buflist, not a new bar item).

### Interview Summary
- Match field: buffer `name`.
- Category headers: **none** (group ordering + per-buffer prefix only).
- Config format: JSON.
- Multiple match precedence: first match wins.

### Metis Review (gaps addressed)
- Must save+restore user’s `buflist.format.*`, `buflist.look.sort`, `buflist.look.signals_refresh` on unload/reload.
- Prefer buflist sort on `local_variables.<var>` + format injection; do **not** modify real buffer name.
- Handle JSON errors by keeping last-good config.
- Use zero-padded sort keys.
- Avoid unverified hook_modifier names.

## Work Objectives
### Core Objective
Categorize buffers and adjust buflist ordering + display prefix **without** altering global buffer names or requiring a custom bar item.

### Deliverables
- `modules/programs/weechat/_/bufcat/bufcat.py`
- `modules/programs/weechat/_/bufcat/bufcat.json` (example)
- `modules/programs/weechat/_/scripts.nix` updated to package and optionally include `bufcat.py`
- `modules/programs/weechat/options.nix` updated with `jvf.programs.weechat.bufcat.*` options
- Tests (pure Python, no WeeChat dependency) + `make check` / `nix flake check` passes

### Definition of Done (agent-verifiable)
- `make check` passes.
- `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.programs.weechat.plugins.scripts` includes bufcat package when enabled.
- `python -m py_compile modules/programs/weechat/_/bufcat/bufcat.py` succeeds.
- `python -m unittest` (new tests) passes.

### Must Have
- Group/sort buflist using `buflist.look.sort` with `local_variables.bufcat_order`.
- Display prefix via `buflist.format.buffer` and `buflist.format.buffer_current` using `${buffer.local_variables.bufcat_prefix}`.
- First-match-wins on substring patterns.
- Default category when no category matches.
- Save+restore all modified WeeChat options on unload/reload.

### Must NOT Have
- No custom bar item replacing buflist.
- No hook_modifier-based renaming of `buffer_name` / `buffer_short_name`.
- No modifying real `buffer.name` / `buffer.short_name` / log titles.
- No external Python deps (no PyYAML/pytest required).

## Verification Strategy
- Test decision: **tests-after**, pure `unittest` (stdlib) + fake WeeChat adapter.
- QA policy: each TODO includes 2 scenarios + evidence file path.
- Evidence: `.sisyphus/evidence/task-{N}-{slug}.txt`

## Execution Strategy
### Parallel Execution Waves
Wave 1 (design + scaffolding)
- T1 JSON schema + matching algorithm (decision-locked)
- T2 Nix integration design (where to wire, options)

Wave 2 (implementation)
- T3 Implement `bufcat.py` core logic + adapter
- T4 Implement buflist patch/restore + signal hooks + `/bufcat` commands
- T5 Package script in Nix + wire enable option + startup load command

Wave 3 (verification)
- T6 Add unit tests (fake adapter)
- T7 Add example config + docs/comments

### Dependency Matrix (full)
- T1 blocks T3/T4/T6/T7
- T2 blocks T5
- T3 blocks T4/T6
- T4 blocks T6
- T5 blocks final verification

### Agent Dispatch Summary
- Wave 1: 2 tasks (business-logic + writing-nix-code)
- Wave 2: 3 tasks (business-logic + writing-nix-code)
- Wave 3: 2 tasks (business-logic + writing)

## TODOs

- [x] 1. Lock JSON config schema + matching rules

  **What to do**:
  - Define **exact** JSON schema (versioned) and matching behavior.
  - Decide defaults so executor has no judgment calls:
    - Matching: literal substring search only.
    - Case sensitivity: **case-sensitive** by default; optional global `case_insensitive: true`.
    - Match target: buffer `name` (user decision). If unavailable, fall back to `full_name`.
    - First-match-wins: iterate categories in file order.
    - Sorting: primary `category.order` (int) → zero-pad to 3 digits string localvar; secondary `buffer.number`.
  - Output: document schema in `bufcat.py` docstring + `bufcat.json` example.

  **Must NOT do**: regex/glob matching; YAML.

  **Recommended Agent Profile**:
  - Category: `business-logic` — Reason: schema+algorithm decisions.
  - Skills: []

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: [T3,T4,T6,T7] | Blocked By: []

  **References**:
  - Repo draft: `.sisyphus/drafts/weechat-buflist-categories.md`
  - WeeChat buflist knobs: `buflist.look.sort`, `buflist.format.buffer`, `${buffer.local_variables...}` (from earlier research)

  **Acceptance Criteria**:
  - [ ] JSON schema written down (keys, types, defaults, examples) with no TODOs/?? left.

  **QA Scenarios**:
  ```
  Scenario: Config supports first-match-wins
    Tool: Bash
    Steps: Write 2 categories with overlapping patterns; confirm spec says first match wins.
    Expected: Spec explicitly states iteration order and precedence.
    Evidence: .sisyphus/evidence/task-1-schema.txt

  Scenario: Config has safe defaults
    Tool: Bash
    Steps: Inspect schema for optional fields; ensure defaults are stated.
    Expected: No field has ambiguous default.
    Evidence: .sisyphus/evidence/task-1-defaults.txt
  ```

  **Commit**: YES | Message: `feat(weechat): define bufcat config schema`

- [x] 2. Design Nix wiring + options surface
  **What to do**:
  - Decide option names under `jvf.programs.weechat.bufcat.*`:
    - `enable` (bool, default false)
    - `configPath` (nullOr str, default null → script uses `${weechat_dir}/bufcat.json`)
  - Decide how script is loaded on startup when enabled:
    - Append to `jvf.programs.weechat.extraInitCommands`: `/python load bufcat.py`
  - Decide whether bufcat script is added to `defaultScripts` when enabled.

  **Must NOT do**: manage user home files via HM; introduce new global roles.

  **Recommended Agent Profile**:
  - Category: `general` — Reason: small cross-file Nix module wiring.
  - Skills: [`writing-nix-code`]

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: [T5] | Blocked By: []

  **References**:
  - `modules/programs/weechat/default.nix` — imports list
  - `modules/programs/weechat/options.nix` — option namespace pattern
  - `modules/programs/weechat/_/scripts.nix` — script derivation pattern (`viModeScript`)
  - `modules/programs/weechat/_/init.nix` — init command generation

  **Acceptance Criteria**:
  - [ ] Concrete list of file edits and exact option names decided.

  **QA Scenarios**:
  ```
  Scenario: Options are minimal
    Tool: Bash
    Steps: Review option list; ensure only enable + configPath are exposed.
    Expected: No over-designed option surface.
    Evidence: .sisyphus/evidence/task-2-options.txt

  Scenario: Startup load is deterministic
    Tool: Bash
    Steps: Confirm plan uses /python load bufcat.py via init script.
    Expected: No reliance on implicit autoload directories.
    Evidence: .sisyphus/evidence/task-2-startup.txt
  ```

  **Commit**: NO (design-only)

- [x] 3. Implement `bufcat.py` core (pure logic + adapter boundary)
  **What to do**:
  - Create `modules/programs/weechat/_/bufcat/bufcat.py`.
  - Structure as:
    - Pure functions: load/validate config, choose_category(buffer_name,...), zero_pad_order.
    - WeeChat integration behind an adapter object so tests can fake it.
  - Config validation rules:
    - require top-level `version: 1`.
    - `categories` array entries: `name` (str), `order` (int 0-999), `prefix` (str), `patterns` (list[str]).
    - `default_category`: same fields minus patterns.
  - JSON error handling: keep last-good config in memory; on parse error print to core buffer.

  **Must NOT do**: import third-party libs.

  **Recommended Agent Profile**:
  - Category: `business-logic` — Reason: logic-heavy, correctness.
  - Skills: []

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: [T4,T6] | Blocked By: [T1]

  **References**:
  - Path conventions: `modules/programs/weechat/_/` holds helper assets

  **Acceptance Criteria**:
  - [ ] `python -m py_compile modules/programs/weechat/_/bufcat/bufcat.py` succeeds.

  **QA Scenarios**:
  ```
  Scenario: First match wins
    Tool: Bash
    Steps: Run unit tests (added in T6) for overlapping patterns.
    Expected: Category chosen is the first matching category in config order.
    Evidence: .sisyphus/evidence/task-3-first-match.txt

  Scenario: Malformed JSON keeps last-good
    Tool: Bash
    Steps: Unit test loads valid config then invalid JSON; ensure last_good remains.
    Expected: No exception escapes; error message recorded.
    Evidence: .sisyphus/evidence/task-3-json-error.txt
  ```

  **Commit**: YES | Message: `feat(weechat): add bufcat core logic` | Files: [`modules/programs/weechat/_/bufcat/bufcat.py`]

- [x] 4. Implement WeeChat behavior: localvars, buflist patch/restore, signals, `/bufcat`
  **What to do**:
  - On load/register:
    - Save current values of:
      - `buflist.look.sort`
      - `buflist.format.buffer`
      - `buflist.format.buffer_current`
      - `buflist.look.signals_refresh`
    - Set `buflist.look.sort = "local_variables.bufcat_order,number"` (or prepend to existing sort if desired; decision: replace and restore).
    - Patch `buflist.format.buffer` and `..._current` by **prepending** conditional prefix:
      - `${if:${buffer.local_variables.bufcat_prefix}?${buffer.local_variables.bufcat_prefix}:}` + `<original_format>`
    - Ensure `buflist.look.signals_refresh` contains `bufcat_categorized`.
  - Categorization pass:
    - Iterate `infolist_get("buffer", "", "")`.
    - For each buffer: compute category and set:
      - `localvar_set_bufcat_order = zero_pad(order)`
      - `localvar_set_bufcat_prefix = prefix`
  - Hooks:
    - `buffer_opened` and `buffer_renamed` → categorize that buffer (or recategorize all if API limitations).
    - Provide `/bufcat reload`, `/bufcat status`, `/bufcat list`.
  - On unload:
    - Restore saved config options.
    - Clear localvars `bufcat_order`/`bufcat_prefix` for all existing buffers.

  **Must NOT do**: hook_modifier renames; custom bar item.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — Reason: WeeChat API surface + careful state restore.
  - Skills: []

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: [T6] | Blocked By: [T1,T3]

  **References**:
  - Must preserve user settings (Metis guardrail).
  - Use localvars + buflist format injection (prior research).

  **Acceptance Criteria**:
  - [ ] Script defines unload callback that restores all overwritten buflist options.
  - [ ] Script sends refresh signal after categorization (custom signal present in `buflist.look.signals_refresh`).

  **QA Scenarios**:
  ```
  Scenario: Load patches buflist and sets localvars
    Tool: Bash
    Steps: Run unit tests with FakeWeeChatAdapter that records config sets and localvar sets.
    Expected: sort/format/signals_refresh set; each fake buffer gets bufcat_order+bufcat_prefix.
    Evidence: .sisyphus/evidence/task-4-load.txt

  Scenario: Unload restores
    Tool: Bash
    Steps: Unit test calls unload; verify adapter restored exact original config strings.
    Expected: All restored exactly, localvars removed.
    Evidence: .sisyphus/evidence/task-4-unload.txt
  ```

  **Commit**: YES | Message: `feat(weechat): apply buflist categories via localvars` | Files: [`modules/programs/weechat/_/bufcat/bufcat.py`]

- [x] 5. Nix packaging + enable option wiring

  **What to do**:
  - In `modules/programs/weechat/options.nix`:
    - Add `jvf.programs.weechat.bufcat.enable` (mkEnableOption; sub-feature toggle OK).
    - Add `jvf.programs.weechat.bufcat.configPath` (nullOr str).
  - In `modules/programs/weechat/_/scripts.nix`:
    - Add derivation `bufcatScript` using same pattern as `viModeScript`:
      - `passthru.scripts = [ "bufcat.py" ];`
      - install to `$out/share/bufcat.py` (or `$out/share/weechat/bufcat.py` but ensure consistent with viMode).
    - Add to default scripts when enabled: `defaultScripts ++ lib.optional cfg.bufcat.enable bufcatScript` (update module args to include `config`).
  - In `modules/programs/weechat/_/init.nix` or `_/*.nix` submodule:
    - When enabled, append `/python load bufcat.py` to `cfg.extraInitCommands`.
    - If `configPath` set, pass it via WeeChat plugin var or env:
      - Preferred: set `plugins.var.python.bufcat.config_path = <path>` via generated settings (so script can read it).

  **Must NOT do**: reference `inputs.self` paths inside aspects.

  **Recommended Agent Profile**:
  - Category: `general` — Reason: small Nix edits.
  - Skills: [`writing-nix-code`]

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: [Final verification] | Blocked By: [T2]

  **References**:
  - `modules/programs/weechat/_/scripts.nix` — `viModeScript` packaging pattern
  - `modules/programs/weechat/_/init.nix` — init script command concatenation
  - `modules/programs/weechat/options.nix` — sub-feature enable (`matrix.enable`) precedent

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.programs.weechat.plugins.scripts` contains bufcat when enable=true.
  - [ ] `make check` passes.

  **QA Scenarios**:
  ```
  Scenario: Enable adds script
    Tool: Bash
    Steps: Temporarily enable option in host/role as needed; run nix eval for scripts list.
    Expected: bufcat derivation appears.
    Evidence: .sisyphus/evidence/task-5-eval.txt

  Scenario: Disable is no-op
    Tool: Bash
    Steps: Ensure enable=false; nix eval scripts list.
    Expected: bufcat absent.
    Evidence: .sisyphus/evidence/task-5-disable.txt
  ```

  **Commit**: YES | Message: `feat(weechat): package bufcat script` | Files: [`modules/programs/weechat/options.nix`,`modules/programs/weechat/_/scripts.nix`,`modules/programs/weechat/_/init.nix`]

- [x] 6. Add pure-Python unit tests (no WeeChat runtime)

  **What to do**:
  - Add `modules/programs/weechat/_/bufcat/test_bufcat.py` (or `tests/test_bufcat.py` if repo already has tests dir; if not, keep co-located).
  - Use `unittest`.
  - Implement `FakeWeeChatAdapter` covering:
    - config get/set
    - buffer list
    - localvar set/del
  - Test matrix:
    - first-match-wins
    - default category
    - case_insensitive toggle
    - zero-pad order
    - buflist format patching + restore
    - JSON parse error keeps last-good

  **Must NOT do**: require pytest.

  **Recommended Agent Profile**:
  - Category: `business-logic` — Reason: correctness + regression.
  - Skills: []

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: [Final verification] | Blocked By: [T3,T4]

  **References**:
  - Script structure from T3/T4

  **Acceptance Criteria**:
  - [ ] `python -m unittest` passes (explicit command documented in test file header).

  **QA Scenarios**:
  ```
  Scenario: Restore is exact
    Tool: Bash
    Steps: Run unittest; inspect FakeAdapter recorded restore calls.
    Expected: Restored strings exactly match originals.
    Evidence: .sisyphus/evidence/task-6-restore.txt

  Scenario: Prefix injection is safe
    Tool: Bash
    Steps: Unit test original format starting with ${color_hotlist}; ensure prefix is prepended before it.
    Expected: Patched format == prefix_expr + original.
    Evidence: .sisyphus/evidence/task-6-prefix.txt
  ```

  **Commit**: YES | Message: `test(weechat): add bufcat unit tests` | Files: [tests path]

- [x] 7. Add example `bufcat.json` + usage notes

## Final Verification Wave (MANDATORY)
- [x] F1. Plan Compliance Audit — oracle (minor: config_path env vs plugin var gap)
- [x] F2. Code Quality Review — unspecified-high
- [x] F3. Real Manual QA (script load in WeeChat via tmux automation) — unspecified-high
- [x] F4. Scope Fidelity Check — deep (false positive: iamb in separate commit)

## Commit Strategy
- Prefer 3 commits:
  1) bufcat script (core + integration)
  2) Nix wiring
  3) tests + example config

## Success Criteria
- Script reliably groups buflist by category order and prepends category prefix.
- Script unload leaves WeeChat buflist config exactly as before.
- Config errors are non-fatal and visible to user.
- Flake remains valid (`make check`).
