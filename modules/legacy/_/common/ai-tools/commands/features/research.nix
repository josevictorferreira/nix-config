{ config
, lib
, inputs
, ...
}:
let
  commandName = "feat-research";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Research best practices and elegant solutions for a feature topic";
    prompt = ''
      <objective>
      Research the topic "$ARGUMENTS" to identify best practices and the most elegant implementation strategies.
      The output must serve as a high-fidelity "Architectural Seed" for the subsequent spec and plan phases.
      </objective>

      <context>
      Existing features: ! `ls -d .docs/features/* 2>/dev/null || echo "No existing features found"`
      </context>

      <process>
      1. **Directory Setup**:
          - Analyze the "Existing features" list to find the highest sequential number (e.g., if `001-login` exists, next is `002`).
          - Determine a short "slug" name for the feature based on "$ARGUMENTS" (e.g., `auth-system`).
          - Define the target path: `./.docs/features/XXX-{slug}/research.md`.

      2. **Analysis & Brainstorming**:
          - Analyze requirements for "$ARGUMENTS" using Chain-of-Thought reasoning.
          - Identify "Implementation Primitives": specific libraries, patterns, or existing files in this repo to mimic.
          - Focus on AI-friendliness: low coupling, clear naming, explicit state, and robust types.

      3. **Develop Solutions**:
          - **The Elegant Solution**: The recommended approach emphasizing simplicity and robustness.
          - **Alternatives**: Provide at least 2 distinct alternative approaches (Total 3+ options).
          - Include a **Trade-off Matrix** (Elegance vs. Performance vs. Implementation Cost).

      4. **Output Generation**:
          - Create the directory if it doesn't exist.
          - Write findings to the `research.md` file.
      </process>

      <output_structure>
      - **Context & Constraints**: Why this is being built and what limits us.
      - **The Elegant Solution**: Detailed architecture, reasoning, and why it's the most elegant choice.
      - **Implementation Primitives**: Suggested types, file structures, and specific internal patterns to follow.
      - **Trade-off Matrix**: Comparison of the primary solution and alternatives.
      - **Citations & References**: Sources, documentation, or standard library references.
      </output_structure>

      <success_criteria>
      - A new feature directory is created with the correct sequential number.
      - `research.md` contains 1 primary recommendation and at least 2 alternatives.
      - Implementation Primitives are identified to guide the plan phase.
      - Content specifically addresses "elegance" and "vibe-coding" friendliness.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
