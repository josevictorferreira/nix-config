{
  config,
  lib,
  inputs,
  ...
}:
let
  commandName = "feat-spec";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Create a Product Requirement Document (PRD) for a feature";
    prompt = ''
      <objective>
      Create a Product Definition Specification for "$ARGUMENTS".
      This includes detailed functional and non-functional requirements written to a sequentially numbered directory.
      </objective>

      <context>
      Existing directories: ! `ls -d .docs/features/* 2>/dev/null`
      </context>

      <process>
      1. **Directory Resolution**:
          - Check if a directory for "$ARGUMENTS" already exists (from the `feat-research` step).
          - If it exists, use that path.
          - If it does NOT exist, calculate the next sequential number (check `Existing directories`) and create a new path: `.docs/features/XXX-{slug}/`.

      2. **Draft Specification**:
          - **Functional Requirements**: specifically what the system must do.
          - **Non-Functional Requirements**: performance, security, reliability (include only if required/relevant).
          - **User Stories/Use Cases**: How the user interacts with the feature.

      3. **File Creation**:
          - Write the content to `.docs/features/{number}-{name}/spec.md`.
      </process>

      <output>
      Files created:
      - `.docs/features/{number}-{name}/spec.md`
      </output>

      <verification>
      Verify that the specification file is legible and covers both functional and non-functional aspects before saving.
      </verification>

      <success_criteria>
      - Specification document created in the correctly numbered folder.
      - Clear separation between functional and non-functional requirements.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
