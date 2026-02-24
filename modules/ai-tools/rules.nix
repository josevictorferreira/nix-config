# Aspect: ai-tools-rules
# Base AI rule definitions (global constraints for all AI consumers).
# Provides jvf.aiTools.baseRule options and propagates content to
# opencode, claudecode, droid, and gemini base rules.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.aiTools.baseRule = {
        content = lib.mkOption {
          type = lib.types.str;
          description = "The content of the rules file.";
          default = ''
            **IMPORTANT** In all interactions, plans, and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
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
        jvf.programs.opencode.baseRules = cfg.content;
        jvf.programs.claudecode.baseRules = cfg.content;
        jvf.programs.droid.baseRules = cfg.content;
        jvf.programs.gemini.baseRules = cfg.content;
      };
    };
in
{
  flake.modules.nixos.ai-tools-rules = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-rules = mkConfig { isDarwin = true; };
}
