{ config
, lib
, inputs
, ...
}:
let
  commandName = "session-retrospective";
  commandFullName = inputs.lib.strings.kebabToHuman commandName;
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Analyze session friction points, distill learnings into .docs/rules.md, and ensure AGENTS.md references it.";
    prompt = ''
      # ${commandFullName}

      SESSION RETROSPECTIVE: Notes for Your Future Self

      Analyze this entire session to identify where you struggled, got stuck, or wasted time. Distill those friction points into actionable lessons.

      ## Core Question

      Ask yourself: **"What information, if I had known it beforehand, would have helped me the most in this session?"**

      ## A) Analyze the Session

      Review your work and identify:
      1. **Friction points** - Where did you get stuck the longest? What was hardest to implement?
      2. **Time sinks** - What took disproportionately long due to missing knowledge or wrong assumptions?
      3. **Repeated attempts** - Where did you try multiple approaches before finding the right one?
      4. **Surprises** - What behaved unexpectedly? What did you have to learn the hard way?

      For each friction point, ask: "If I encounter this again, what should I do differently?"

      ## B) Update `.docs/rules.md`

      Write lessons to `.docs/rules.md` (single file, create if needed).

      **What belongs here:**
      - Knowledge that would have saved you significant time (>15-20 min)
      - Patterns/gotchas likely to recur in this codebase
      - Non-obvious behaviors, quirks, or requirements you discovered
      - Process lessons (verification steps, order of operations, etc.)

      **What does NOT belong:**
      - One-off fixes unlikely to recur
      - Obvious things any developer would know
      - Preferences or style opinions
      - Verbose explanations (keep it tight)

      **Hard limits:**
      - Add at most 3-5 lessons per session
      - Each lesson: 2-4 lines max
      - If no significant friction occurred: write "No significant learnings to record." and skip

      **De-dupe (mandatory):**
      - Before adding, read existing `.docs/rules.md`
      - If equivalent lesson exists: update/clarify it instead of duplicating
      - Consolidate related lessons into one if they overlap

      **Format per lesson:**
      ```
      ### [Short descriptive title]
      **Lesson:** [What to do/know - imperative, actionable]
      **Context:** [Why this matters - 1 sentence]
      **Verify:** [Quick check: command, file, or test to confirm]
      ```

      ## C) Update `AGENTS.md` (only if missing)

      Ensure `AGENTS.md` contains an instruction to read `.docs/rules.md` before implementing.
      - If already present: do nothing
      - If missing: add near the top: "Before starting any implementation, read `.docs/rules.md` for project-specific lessons and gotchas."

      ## Output

      1. Summary of friction points identified (1-2 sentences each)
      2. Lessons added/updated in `.docs/rules.md` (verbatim)
      3. Whether `AGENTS.md` was updated (yes/no + text if yes)
      4. Confirmation: de-duped against existing content
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
