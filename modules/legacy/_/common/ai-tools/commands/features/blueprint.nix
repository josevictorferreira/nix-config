{ config
, lib
, inputs
, ...
}:
let
  commandName = "feat-blueprint";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Create a complete feature blueprint (Spec + Plan + Tasks) in one go";
    prompt = ''
      <objective>
      Create a comprehensive Product Definition Specification, Implementation Plan, and Phased Task List for "$ARGUMENTS".
      This unifies the Spec, Plan, and Tasks generation into a single seamless workflow.
      </objective>

      <context>
      Existing directories: ! `ls -d .docs/features/* 2>/dev/null`
      </context>

      <process>
      1. **Directory Resolution**:
          - Check if a directory for "$ARGUMENTS" already exists (e.g. from `feat-research`).
          - If it exists, use that path.
          - If it does NOT exist, calculate the next sequential number (check `Existing directories`) and create a new path: `.docs/features/XXX-{slug}/`.

      2. **Draft Specification (Spec)**:
          - **Functional Requirements**: specifically what the system must do.
          - **Non-Functional Requirements**: performance, security, reliability (include only if required/relevant).
          - **User Stories/Use Cases**: How the user interacts with the feature.
          - **Review**: Address any doubts or ambiguities ensuring the spec is solid.

      3. **Develop Technical Plan (Plan)**:
          - Based on the Spec above.
          - Break down the architecture and logic flow.
          - Provide a detailed step-by-step implementation strategy.
          - **Review**: Ensure all steps are clearly outlined and feasible.

      4. **Construct Phased Tasks (Tasks)**:
          - Convert the Plan into a strictly ordered, phased task list.
          - **Phases**: Group tasks into Phase 1, Phase 2, etc.
          - **Gates**: Each phase MUST end with a mandatory testing gate (All tests pass, No linting errors).
          - **Ordering**: Strictly sequential by implementation dependency.
          - **Async**: Mark tasks that can be done asynchronously where possible.

      5. **Output Generation**:
          - Create the directory if needed.
          - Write content to `.docs/features/{number}-{name}/spec.md`.
          - Write content to `.docs/features/{number}-{name}/plan.md`.
          - Write content to `.docs/features/{number}-{name}/tasks.md` (as a Markdown checklist).
      </process>

      <output>
      Files created:
      - `.docs/features/{number}-{name}/spec.md`
      - `.docs/features/{number}-{name}/plan.md`
      - `.docs/features/{number}-{name}/tasks.md`
      </output>

      <verification>
      - Verify specification is legible and covers requirements.
      - Verify plan accounts for requirements and architecture.
      - Verify tasks are phased, strictly ordered, and include testing gates.
      </verification>

      <success_criteria>
      - All three documents (Spec, Plan, Tasks) are created in the correct feature folder.
      - Documents are consistent with each other.
      - Task list is actionable and gated.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
