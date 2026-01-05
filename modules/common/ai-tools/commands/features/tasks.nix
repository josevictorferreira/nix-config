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
          - Read `plan.md` (Technical Plan) and `spec.md` (Product Requirements).

      2. **Construct Phases**:
          - Break the plan into "Phases" (e.g., Phase 1, Phase 2).
          - Each phase must be independent and should not break the test suite. All tests must pass(GREEN) after each phase. Plan accordingly with that in mind.
          - All linting should also pass(no offenses or warnings across the whole project).
          - **Ordering Rule**: Phases must be strictly sequential ordered by Implementation order, ensuring each subsequent phase builds upon the previous without regression.
          - Never make a phase with only a single type of task (for example a single phase of testing for all other phases).
          - **Async Rule**: Identify instances where tasks/phases can be developed asynchronously and explicitly mark them.

      3. **Define Gates**:
          - Note that development cannot proceed to Phase $N+1$ until Phase $N$ tests pass.
          - The whole project test suite should pass before proceeding to the next phase.
          - The whole project files should be linted and should not have any offenses/warnings.

      4. **Output**:
          - Create `./.docs/features/{number}-{name}/tasks.md`
          - Format as a Markdown checklist.
      </process>

      <output>
      Files created:
      - `./.docs/features/{number}-{name}/tasks.md`
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
