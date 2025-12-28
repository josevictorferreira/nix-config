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
      Generate a comprehensive research document stored in a new, sequentially numbered feature folder.
      </objective>

      <context>
      Existing features: ! `ls -d .docs/features/* 2>/dev/null || echo "No existing features found"`
      </context>

      <process>
      1. **Directory Setup**:
          - Analyze the "Existing features" list to find the highest sequential number (e.g., if `001-login` exists, next is `002`).
          - Determine a short "slug" name for the feature based on "$ARGUMENTS" (e.g., `auth-system`).
          - Define the target path: `./.docs/features/XXX-{slug}/research.md`.

      2. **Conduct Research**:
          - content: Analyze current academic literature, technical documentation, and recent studies regarding "$ARGUMENTS".
          - Focus: Look for the "most elegant" way to implement this in a product environment.

      3. **Develop Solutions**:
          - Primary Solution: The recommended "elegant" approach.
          - Alternatives: You MUST provide at least 2 distinct alternative approaches (Total of 3+ options).
          - For each suggestion, provide proper citations, source attribution, or references to standard libraries/patterns.

      4. **Output Generation**:
          - Create the directory if it doesn't exist.
          - Write the findings to the `research.md` file.
      </process>

      <output>
      Files created:
      - `./.docs/features/{number}-{name}/research.md`
      </output>

      <success_criteria>
      - A new feature directory is created with the correct sequential number.
      - `research.md` contains 1 primary recommendation and at least 2 alternatives.
      - Sources and citations are included.
      - Content specifically addresses "elegance" and "best practices".
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
