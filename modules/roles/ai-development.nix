{
  config,
  lib,
  pkgs,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.roles.aiDevelopment;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports = [
    ../common/ai-tools/default.nix
    ../programs/opencode
    ../programs/claudecode.nix
    ../programs/droid.nix
  ];

  options.jvf.roles.aiDevelopment = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable vibe coding tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.enable = true;
    jvf.programs.claudecode.enable = true;

    jvf.aiTools.agents."nix-expert".enable = lib.mkDefault true;
    jvf.aiTools.agents."code-reviewer".enable = lib.mkDefault true;
    jvf.aiTools.agents."security-auditor".enable = lib.mkDefault true;
    jvf.aiTools.agents."documenter".enable = lib.mkDefault true;

    jvf.aiTools.commands."do".enable = lib.mkDefault true;
    jvf.aiTools.commands."ask".enable = lib.mkDefault true;
    jvf.aiTools.commands."nix-check".enable = lib.mkDefault true;
    jvf.aiTools.commands."flake-update".enable = lib.mkDefault true;
    jvf.aiTools.commands."review".enable = lib.mkDefault true;
    jvf.aiTools.commands."commit-msg".enable = lib.mkDefault true;

    jvf.aiTools.mcp.shadcn.enable = lib.mkDefault true;
    jvf.aiTools.mcp.context7.enable = lib.mkDefault true;
    jvf.aiTools.mcp.playwright.enable = lib.mkDefault true;

    jvf.aiTools.mcp."mcp-nixos".enable = lib.mkDefault (!isDarwin);

    users.users."${cfg.username}".packages = [
      pkgs.code-cursor
      pkgs.cursor-cli
      pkgs.goose-cli
    ];
  };
}
