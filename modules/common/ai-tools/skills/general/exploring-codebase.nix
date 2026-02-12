{ config
, lib
, inputs
, ...
}:

let
  skillName = "exploring-codebase";
  cfg = config.jvf.aiTools.skills."${skillName}";
  skillFullName = inputs.lib.strings.kebabToHuman skillName;
  skillOptions = {
    name = skillName;
    description = "Semantic codebase navigation and search. Use when the user asks to find code, understand feature implementation, locate logic patterns, or map code relationships. This skill leverages the 'ck' engine to perform semantic, regex, and hybrid searches.";
    allowed-tools = [
      "Read"
      "Bash"
    ];
    model = "openrouter/openai/gpt-oss-120b:exacto";
    tags = [
      "explorer"
    ];
    references = {
      "cli_guide" = ''

        Use the ck search tools to find files.

        ## Core Search Commands

        | Intent | Flag | Example |
        | :--- | :--- | :--- |
        | **Semantic** | `--sem` | `ck --sem "error handling" src/` |
        | **Regex** | `-n` / `-R` | `ck -n "TODO" *.rs` |
        | **Hybrid** | `--hybrid` | `ck --hybrid "connection timeout" src/` |
      '';
    };

    prompt = ''
      # Exploring Codebase: Semantic Code Search

      This skill operates the `ck` search engine to find code by **meaning**, not just keywords.

      **IMPORTANT** Return the file outputs to the user, never worry about logic or implementing something.

      ## Workflow Strategy

      When a user requests to find or understand code, analyze the request to determine the appropriate search strategy:

      ### 1. Semantic Search (`ck_semantic_search`)
      **Trigger:** User asks about concepts, "how things work," or high-level features where keywords might vary.
      *   *Example:* "How does authentication work?" or "Find the error handling logic."
      *   *Action:* Use `ck_semantic_search` to find intent matches.

      ### 2. Regex/Lexical Search (`ck_regex_search`)
      **Trigger:** User asks for exact strings, specific variable names, TODOs, or distinct code patterns.
      *   *Example:* "Find all TODOs," "Where is `process_payment` defined?", or "Find standard 'FIXME' tags."
      *   *Action:* Use `ck_regex_search` for exact pattern matching (grep-style).

      ### 3. Hybrid Search (`ck_hybrid_search`)
      **Trigger:** User knows the specific terminology but wants to narrow results by conceptual relevance.
      *   *Example:* "Find connection timeouts in the auth module" (Keyword: "timeout", Concept: "relevance").
      *   *Action:* Use `ck_hybrid_search` to combine keyword precision with semantic ranking.

      ## Tool Configuration Guidelines

      When calling MCP tool functions, adhere to these defaults unless the user specifies otherwise:

      - **page_size**: Set to `10` or `15` to avoid flooding the context window.
      - **snippet_length**: Set to `200` lines (approx) to get sufficient context without full files.
      - **top_k**: Use `50` for broad searches, `10` for specific queries.
      - **full_section**: If the user asks for the "whole function" or "entire class," prefer using `ck_semantic_search` with arguments that retrieve full sections if available, or read the file after locating it.

      ## Result Interpretation

      After receiving search results:
      1.  **Synthesize**: Do not just dump the list. Explain *why* the result is relevant to the query.
      2.  **Pivot**: If results are found, offer to "Inspect file [path]" or "Find usages of [symbol found]".
      3.  **Refine**: If confidence scores are low (<0.4 for semantic), suggest re-phrasing the query or switching to `ck_regex_search`.

      ## CLI Command Generation

      If the user asks for the CLI command to run locally instead of having the agent perform it, refer to [references/cli_guide.md](references/cli_guide.md).
    '';
  };
  skillDef = inputs.lib.aiTools.mkSkillModule { inherit skillOptions; };
in
{
  options.jvf.aiTools.skills."${skillName}" = skillDef.options;
  config = lib.mkIf cfg.enable skillDef.config;
}
