{ ... }:
{
  name = "self-learn";
  description = "End-of-session learning loop: distill friction into AGENTS.md and improve the skills used in the session.";
  agent = "";
  prompt = ''
    # Self-Learn

    SELF-LEARN: Notes for Your Future Self + Skill Improvements

    Analyze this entire session to identify where you struggled, got stuck, or wasted time. Distill those friction points into actionable lessons AND propose concrete improvements to the skills you used (and potentially a new skill if a clear repeatable workflow emerged).

    ## ⚠️ Quality Bar — Read This First

    **Do NOT feel pressure to add anything.** A session with no recorded changes is a perfectly valid outcome. The cost of low-signal noise (in `AGENTS.md`, in skills, in new scripts) is high — it pollutes future context and erodes trust in the lessons that DO matter.

    Hard rules:
    - **Default to silence.** If a candidate lesson/skill-edit/script does not clearly clear the bar below, drop it.
    - **No filler, no padding, no "nice-to-haves".** Only record things that would have demonstrably saved you significant time or prevented a real mistake.
    - **No speculative additions.** If you're not sure it will recur, do not record it.
    - **No restating the obvious.** If a competent engineer using this stack would already know it, skip it.
    - **No new skills unless clearly justified.** Extending an existing skill is almost always better. A new skill must be reusable across many future sessions, not a one-off.
    - **No scripts unless the procedure is multi-step, error-prone, AND likely to repeat.** A two-line command is not a script.

    If after honest review nothing clears the bar, output the empty-result statements in the Output section and stop. That is success, not failure.

    ## Core Question

    Ask yourself: **"What information, if I had known it beforehand, would have helped me the most in this session?"**

    Apply this question at TWO levels:
    1. **Project level** → lessons go into `AGENTS.md` / `CLAUDE.md`
    2. **Skill level** → improvements go into the skill files at `~/.config/nix/modules/ai-tools/_/skills/<category>/<name>.nix`

    ---

    ## A) Analyze the Session

    Review your work and identify:
    1. **Friction points** — Where did you get stuck the longest? What was hardest to implement?
    2. **Time sinks** — What took disproportionately long due to missing knowledge or wrong assumptions?
    3. **Repeated attempts** — Where did you try multiple approaches before finding the right one?
    4. **Surprises** — What behaved unexpectedly? What did you have to learn the hard way?
    5. **Skills used** — Which skills (loaded via the `skill` tool) were actually invoked this session? List them by name.
    6. **Repeatable subtasks** — Did you perform a multi-step procedure that could be encoded as a script?

    For each friction point, ask: "If I encounter this again, what should I do differently?"

    ---

    ## B) Update Project Lessons (`AGENTS.md` / `CLAUDE.md`)

    Same rules as `session-retrospective`:

    **What belongs:**
    - Knowledge that would have saved you significant time (>15-20 min)
    - Patterns/gotchas likely to recur in this codebase
    - Non-obvious behaviors, quirks, or requirements you discovered
    - Process lessons (verification steps, order of operations)

    **What does NOT belong:**
    - One-off fixes unlikely to recur
    - Obvious things any developer would know
    - Preferences or style opinions
    - Verbose explanations

    **Hard limits:**
    - At most 3-5 lessons per session
    - Each lesson: 2-4 lines max
    - If no significant friction occurred: write "No significant project-level learnings to record." and skip

    **De-dupe (mandatory):** Read existing `AGENTS.md` / `CLAUDE.md` first. Update/clarify equivalent lessons instead of duplicating.

    **Format per lesson:**
    ```
    ### [Short descriptive title]
    **Lesson:** [What to do/know — imperative, actionable]
    **Context:** [Why this matters — 1 sentence]
    **Verify:** [Quick check: command, file, or test to confirm]
    ```

    Ensure `AGENTS.md` instructs reading `AGENTS.md`/`CLAUDE.md` before implementing. Add it near the top if missing.

    ---

    ## C) Improve the Skills Used in This Session

    For EACH skill that was loaded and exercised this session:

    1. **Locate the skill source file**:
       ```
       ~/.config/nix/modules/ai-tools/_/skills/<category>/<name>.nix
       ```
       Use `Glob` or `Grep` if you don't know the path. The skill name in the `skill` tool maps to `<category>/<name>.nix` under that root.

    2. **Identify what was missing or wrong** in the skill that cost you time:
       - Missing instruction or warning ("don't do X, do Y")
       - Outdated example or wrong API
       - Missing reference (URL, command, file path)
       - Ambiguous wording that led you down the wrong path
       - Repeatable procedure that was described in prose but should be a script

    3. **Apply changes directly to the `.nix` skill file**:
       - Edit the `prompt` field for prose updates (instructions, gotchas, examples)
       - Edit the `description` field if trigger conditions need tightening
       - Edit `allowed-tools` if a tool was needed but not whitelisted
       - For multi-step repeatable procedures, add a script. The skill DSL supports `scripts."<name>"` (mapped to `skills/<skill>/scripts/<name>` at runtime). If the skill doesn't already have a `scripts` attribute, see an existing skill that does (e.g. one of the meta or research skills) and follow that pattern.

    4. **Skill-improvement quality bar** (same spirit as project lessons):
       - Only add things that would have saved you >10 min
       - Keep additions tight; do not bloat the prompt
       - De-dupe against existing skill content
       - Preserve the existing structure and tone of the skill

    5. **One file at a time, atomic edits**: Read → edit → verify with `nix-instantiate --parse <file>` (or rely on flake check at the end).

    ---

    ## D) Propose / Create a New Skill (Only If Clearly Justified)

    If a coherent, repeatable workflow emerged this session that is NOT covered by any existing skill, you MAY create a new skill.

    **Hard preconditions before creating any new skill:**
    1. **You MUST manually load and read the `skill-creator` skill first** — invoke `skill(name="skill-creator")` and follow its instructions verbatim. Do not skip this step.
    2. The workflow must be plausibly reusable across future sessions (not a one-off).
    3. It must not significantly overlap with an existing skill — prefer extending an existing skill over creating a new one.

    **Implementation steps for a new skill:**
    1. Choose a category directory under `~/.config/nix/modules/ai-tools/_/skills/` (or create a new one if no fit exists).
    2. Create `<category>/<kebab-name>.nix` following the patterns in sibling skills (e.g. `meta/skill-creator.nix`, `research/research-tools.nix`).
    3. Register the skill in `~/.config/nix/modules/ai-tools/skills.nix` inside the `skills = { ... }` attrset, kebab-case key matching the skill name.
    4. If the skill bundles helper scripts/agents/references, place them in a co-located `_/<skill-name>/` directory (the `_/` prefix excludes them from import-tree auto-discovery) and follow the pattern documented in `~/.config/nix/AGENTS.md` (see "Adding Skills with Bundled Resources to ai-tools").
    5. Verify with `nix flake check` (or at minimum `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.aiTools.skills.<new-skill-name>.name`).

    If preconditions are not met, do NOT create a new skill — note the idea in the output instead.

    ---

    ## E) Add Repeatable Scripts (Where Appropriate)

    If during the session you executed a non-trivial multi-step procedure (e.g. a verification sequence, a migration check, a data-extraction recipe), and it belongs to a skill you used, encode it as a script bundled with that skill:

    1. Place the script under the skill's bundled-resources directory: `~/.config/nix/modules/ai-tools/_/skills/_/<skill-name>/<script-name>`.
    2. Reference it from the skill's `scripts` attribute in the `.nix` file so it is materialized at `skills/<skill>/scripts/<script-name>` at runtime.
    3. Update the skill's prompt to mention when to run the script.
    4. Keep scripts shell-portable; prefer `#!/usr/bin/env bash` with `set -euo pipefail`.

    Skip this step if no such procedure occurred.

    ---

    ## F) Verify

    Before declaring done:
    - `nix-instantiate --parse <each-edited-file>` passes for every modified `.nix` file.
    - Run `nix flake check` (or, if too slow, `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.aiTools.skills` to ensure skill registration still evaluates).
    - For new skills: confirm the skill name appears in `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.aiTools.skills --apply 'lib.attrNames'`.

    ---

    ## Output (REQUIRED, in this exact order)

    1. **Friction points** identified (1-2 sentences each).
    2. **Project lessons** added/updated in `AGENTS.md` / `CLAUDE.md` (verbatim) — or "No significant project-level learnings to record."
    3. **Skills exercised this session** (bulleted list of skill names).
    4. **Skill improvements applied** — for each: skill name, file path, summary of change, rationale (1 line). Or "No skill improvements warranted."
    5. **Scripts added** — for each: skill, script path, what it automates. Or "No scripts added."
    6. **New skill created** — name, file path, justification. Or "No new skill created." (and if you considered one but rejected it, briefly say why).
    7. **Verification results** — outputs of parse/eval checks.
    8. **De-dupe confirmation** — confirm you read existing content before adding.
  '';
}
