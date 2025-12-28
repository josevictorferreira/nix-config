{ lib
, config
, ...
}:

let
  cfg = config.jvf.aiTools.baseRule;
  baseRule = ''
    # BASE RULES

    ## Code Search

    Use `ck` MCP tools for all code searching tasks:

    - `ck_semantic_search` - Find code by meaning/intent
    - `ck_lexical_search` - BM25 keyword search
    - `ck_regex_search` - Pattern matching (grep replacement)
    - `ck_hybrid_search` - Combined semantic + regex with RRF ranking

    Prefer these over `grep`, `rg`, or manual file traversal. They are optimized for codebase exploration and return results sorted by relevance.

    ## Documentation Lookup

    Use `context7` MCP tools for up-to-date documentation:

    1. `context7_resolve-library-id` - Resolve package name to library ID
    2. `context7_get-library-docs` - Fetch docs for the resolved library

    Always fetch current documentation before implementing features with unfamiliar APIs or frameworks. This ensures you use correct, non-deprecated patterns.

    ## Tool Priority

    When exploring code or implementing features:

    1. **Search code** → Use `ck_*` tools first
    2. **Check docs** → Use `context7` for framework/library APIs
    3. **Read files** → Use `Read` tool for specific files identified by search
    4. **Fallback** → Use `grep`/`Grep` only when MCP tools are unavailable or not working.
  '';
in
{
  options.jvf.aiTools.baseRule = {
    enable = (lib.mkEnableOption "Enable the base rule file that will be used globally") // {
      default = true;
    };

    content = lib.mkOption {
      type = lib.types.str;
      description = "The content of the rules file.";
      default = baseRule;
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.baseRules = cfg.content;
    jvf.programs.claudecode.baseRules = cfg.content;
  };
}
