{ config
, lib
, inputs
, ...
}:
let
  commandName = "feat-tasks";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Create a phased TODO list with testing gates";
    prompt = ''
      <objective>
      Convert the implementation plan and product spec for "$ARGUMENTS" into a strictly ordered, phased task list stored in `tasks.md`.
      </objective>

      <context>
      File structure: ! `find .docs/features -maxdepth 2 -not -path '*/.*'`
      </context>

      <process>
      1. **Ingest Context**:
          - Locate the folder for "$ARGUMENTS".
          - Read `plan.md` (Technical Plan) and `spec.md` (Requirements).

      2. **Construct Phases**:
          - Break the plan into "Phases" (e.g., Phase 1, Phase 2).
          - **Ordering Rule**: Phases must be strictly sequential.
          - **Async Rule**: Identify instances where tasks/phases can be developed asynchronously and explicitly mark them.

      3. **Define Gates**:
          - Add a mandatory `[ ] Run and Pass Tests` task at the end of **every** phase.
          - Note that development cannot proceed to Phase $N+1$ until Phase $N$ tests pass.

      4. **Output**:
          - Create `.docs/features/{folder}/tasks.md`.
          - Format as a Markdown checklist.
      </process>

      <output>
      Files created:
      - `.docs/features/{folder}/tasks.md`
      </output>

      <success_criteria>
      - `tasks.md` is created containing checkboxes `[ ]`.
      - Tasks are grouped by implementation phase.
      - Each phase ends with a mandatory testing gate.
      - Async opportunities are clearly labeled.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
