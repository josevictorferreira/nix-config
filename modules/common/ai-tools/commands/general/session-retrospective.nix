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
    description = "Add/update high‑impact rules in .docs/rules/* (no duplicates) and, if missing, add to AGENTS.md: “Read .docs/rules/* before implementing.";
    prompt = ''
      # ${commandFullName}

      POST-SESSION RULES UPDATE (mandatory)

      Before you finish, do a “rules + agent instructions” update so future sessions avoid repeating major mistakes.

      A) Update `.docs/rules/*` (high-leverage only)
      Create or update ONE markdown file under `.docs/rules/` with only the most important lessons from this session.

      Goal: capture *high-leverage, reusable* rules that prevent significant failures in future sessions.

      What counts as “important” (must meet ≥1):
      - Caused a bug, broken build, failing tests, or incorrect behavior.
      - Wasted meaningful time (e.g., >20–30 minutes) due to avoidable confusion/rework.
      - Likely to recur in future tasks (not a one-off edge case).
      - A process mistake (missed step, wrong assumption, insufficient verification).
      - Safety/security/data integrity risk or major tech debt.

      What does NOT count:
      - Minor typos, formatting, trivial lint issues.
      - One-off trivia that won’t generalize.
      - Subjective preferences.
      - Long explanations; keep it tight.

      Hard limits:
      - Add at most 3–7 rules total for this session.
      - One rule = 1–4 lines max.
      - If <2 truly important rules: write nothing and say “No high-leverage rules to add.”

      De-dupe requirement (mandatory):
      - Before adding anything, scan existing `.docs/rules/*` for an equivalent rule.
      - If the rule already exists: DO NOT add a new one.
        - Instead, update the existing rule to be clearer/more actionable or to include the missing “Check”.
      - If multiple files contain overlapping versions: consolidate by updating the best one and avoid creating new duplicates.

      File rules:
      - Put it in `.docs/rules/` (create the folder if needed).
      - Name it descriptively (prefer updating an existing relevant file over creating new ones).

      Required format (repeat per rule):
      - **Rule:** (imperative, actionable)
      - **Why:** (1 short sentence)
      - **Check:** (how to verify quickly next time: command, file, test, or checklist item)

      B) Update `AGENTS.md` (only if missing)
      Ensure the project’s `AGENTS.md` instructs agents to read the rules before implementation.
      - Check whether `AGENTS.md` already contains an instruction equivalent to:
        “Before starting any implementation, read `.docs/rules/*`.”
      - If it’s missing, add a short, clear instruction near the top (or in the standard onboarding section).
      - If it already exists, do not add duplicates—leave it unchanged.

      Output requirements (after changes):
      1) The `.docs/rules/...` file path you created/updated
      2) The exact rules added/changed (verbatim)
      3) Whether you updated `AGENTS.md` (yes/no) and the exact text you added (if any)
      4) A 1-line note confirming you de-duped against existing `.docs/rules/*` and kept only high-leverage rules
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
