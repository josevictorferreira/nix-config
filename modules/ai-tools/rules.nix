# Aspect: ai-tools-rules
# Base AI rule definitions (global constraints for all AI consumers).
# Provides jvf.aiTools.baseRule options and propagates content to
# opencode, claudecode, and gemini base rules.
_:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.aiTools.baseRule = {
        content = lib.mkOption {
          type = lib.types.str;
          description = "The content of the rules file.";
          default = ''
            ## 1. Think Before Coding

            **Don't assume. Don't hide confusion. Surface tradeoffs.**

            Before implementing:
            - State your assumptions explicitly. If uncertain, ask.
            - If multiple interpretations exist, present them - don't pick silently.
            - If a simpler approach exists, say so. Push back when warranted.
            - If something is unclear, stop. Name what's confusing. Ask.

            ## 2. Simplicity First

            **Minimum code that solves the problem. Nothing speculative.**

            - No features beyond what was asked.
            - No abstractions for single-use code.
            - No "flexibility" or "configurability" that wasn't requested.
            - No error handling for impossible scenarios.
            - If you write 200 lines and it could be 50, rewrite it.

            Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

            ## 3. Surgical Changes

            **Touch only what you must. Clean up only your own mess.**

            When editing existing code:
            - Don't "improve" adjacent code, comments, or formatting.
            - Don't refactor things that aren't broken.
            - Match existing style, even if you'd do it differently.
            - If you notice unrelated dead code, mention it - don't delete it.

            When your changes create orphans:
            - Remove imports/variables/functions that YOUR changes made unused.
            - Don't remove pre-existing dead code unless asked.

            The test: Every changed line should trace directly to the user's request.

            ## 4. Goal-Driven Execution

            **Define success criteria. Loop until verified.**

            Transform tasks into verifiable goals:
            - "Add validation" → "Write tests for invalid inputs, then make them pass"
            - "Fix the bug" → "Write a test that reproduces it, then make it pass"
            - "Refactor X" → "Ensure tests pass before and after"

            For multi-step tasks, state a brief plan:
            ```
            1. [Step] → verify: [check]
            2. [Step] → verify: [check]
            3. [Step] → verify: [check]
            ```

            Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
          '';
        };
      };
    };

  mkConfig =
    _:
    { config
    , ...
    }:
    let
      cfg = config.jvf.aiTools.baseRule;
    in
    {
      imports = [ mkOptions ];

      config = {
        jvf.programs.opencode.baseRules = "# AGENTS.md\n\n${cfg.content}";
        jvf.programs.claudecode.baseRules = "# CLAUDE.md\n\n${cfg.content}";
        jvf.programs.gemini.baseRules = "# GEMINI.md\n\n${cfg.content}";
      };
    };
in
{
  flake.modules.nixos.ai-tools-rules = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-rules = mkConfig { isDarwin = true; };
}
