{
  config,
  lib,
  inputs,
  ...
}:
let
  commandName = "feat-implement";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Implement a specific phase of a feature, create and run validation tests";
    prompt = ''
      <objective>
      Implement "Phase $2" of feature "$1".
      Read all documentation first, implement code, ensure tests pass, and update the task tracker.
      </objective>

      <context>
      Feature Documentation: ! `find ./.docs/features -name "*$1*" -type d`
      Project Source State: ! `ls -R src/`
      Current Tasks: ! `find ./.docs/features -name "*$1*" -exec cat {}/tasks.md \;`
      </context>

      <process>
      1. **Pre-Implementation Review**:
          - Locate the feature folder for "$1".
          - Read `spec.md`, `plan.md`, and `tasks.md`.
          - Verify that the *previous* phase is complete (checked off in `tasks.md`). If not, STOP and warn the user.

      2. **Implementation (Phase $2)**:
          - Execute only the tasks listed under the requested Phase.
          - Do NOT implement tasks for future phases.
          - Adhere strictly to the "Elegant" solution and "Spec" requirements.

      3. **Testing & Validation**:
          - Create/Update tests for this phase.
          - Run tests: (check in project rules for the command).
          - **CRITICAL**: You cannot mark the phase as done if *any* test fails, errors, or warns. Fix code until tests pass cleanly.
          - **CRITICAL**: DO NOT EVER MARK TESTS AS SKIP.
          - **CRITICAL**: DO NOT EVER CHANGE THE EXPECTED BEHAVIOUR OF A FEATURE TO MAKE THE TESTS PASS.

      4. **Administrative Update**:
          - Once tests pass, update `./.docs/features/{folder}/tasks.md`.
          - Mark the specific tasks and the "Phase Test Gate" as `[x]`.
      </process>

      <testing>
      Run tests (check for the command in the rules of the project)
      </testing>

      <modification_rules>
      - Only modify code relevant to the current phase.
      - Do not bypass test failures.
      </modification_rules>

      <success_criteria>
      - Code for Phase $2 is implemented.
      - All tests (new and existing) pass with 0 errors/warnings.
      - `tasks.md` is updated with checked boxes for the completed items.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
