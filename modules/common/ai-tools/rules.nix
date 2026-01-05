{ lib
, config
, ...
}:

let
  cfg = config.jvf.aiTools.baseRule;
  baseRule = ''
    **IMPORTANT**
    In all interactions, plans, and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
    **IMPORTANT**
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
    jvf.programs.droid.baseRules = cfg.content;
    jvf.programs.gemini.baseRules = cfg.content;
  };
}
