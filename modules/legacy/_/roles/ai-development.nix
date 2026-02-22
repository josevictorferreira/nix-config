{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jvf.roles.aiDevelopment;
in
{
  imports = [
    ../common/ai-tools/default.nix
    ../programs/opencode
    ../programs/claudecode.nix
    ../programs/cursor.nix
    ../programs/droid.nix
    ../programs/gemini.nix
    # Note: llm-proxy migrated to dendritic aspect in Phase 5
  ];
  # Note: programs-ck-search migrated to dendritic aspect (Phase 3)

  options.jvf.roles.aiDevelopment = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable vibe coding tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs."ck-search".enable = true;
    jvf.programs.opencode.enable = true;
    jvf.programs.claudecode.enable = true;
    jvf.programs.cursor.enable = true;
    jvf.programs.droid.enable = true;
    jvf.programs.gemini.enable = true;
    jvf.programs.gemini.antigravity.enable = true;
    jvf.services.llm-proxy.enable = false;
    jvf.programs.cursor = {
      baseRules = config.jvf.aiTools.baseRule.content;
      agents = config.jvf.programs.opencode.agents;
      commands = config.jvf.programs.opencode.commands;
      skills = config.jvf.programs.opencode.skills;
      mcps = config.jvf.programs.claudecode.mcps;
    };

    users.users."${cfg.username}".packages = [
      pkgs.code-cursor
      pkgs.cursor-cli
      pkgs.goose-cli
    ];
  };
}
