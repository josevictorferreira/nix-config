{
  config,
  lib,
  inputs,
  ...
}:
let
  commandName = "feat-plan";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Generate an implementation plan acting as the Plan Agent";
    prompt = ''
      <objective>
      Act as a "Plan Agent" to create a technical implementation plan for "$ARGUMENTS".
      This plan dictates *how* the feature will be built based on available research(if exists) and specs.
      </objective>

      <context>
      Feature Directories: ! `ls -d .docs/features/*`
      </context>

      <process>
      1. **Locate Context**:
          - Identify the correct directory within `.docs/features/` that matches "$ARGUMENTS".
          - Read `research.md`(if exists) and `spec.md` in that directory if they exist.

      2. **Develop Plan**:
          - Analyze the requirements and research(if exists).
          - Break down the architecture and logic flow.
          - detailed step-by-step implementation strategy.

      3. **Review and Doubts**
          - Review and address any doubts or ambiguities in the plan before finalizing, ensure all steps are clearly outlined and any open questions are addressed(ask back to the user your doubts) before finalizing the plan.

      4. **Output**:
          - Write the content to `.docs/features/{matched-folder}/plan.md`.
      </process>

      <output>
      Files created:
      - `.docs/features/{folder}/plan.md`
      </output>

      <success_criteria>
      - Plan accounts for the "Elegant" solution chosen in research.
      - Plan meets all requirements listed in the spec.
      - File is saved specifically to `plan.md` in the feature folder.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
