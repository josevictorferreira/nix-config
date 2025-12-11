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
    #
    # jvf.aiTools = {
    #   agents = {
    #     "nix-expert".enable = lib.mkDefault true;
    #     "code-reviewer".enable = lib.mkDefault true;
    #     "security-auditor".enable = lib.mkDefault true;
    #     "shadc-ui-architect".enable = lib.mkDefault true;
    #     "ui-ux-architect".enable = lib.mkDefault true;
    #     "documenter".enable = lib.mkDefault true;
    #     "container-expert".enable = lib.mkDefault true;
    #     "module-expert".enable = lib.mkDefault true;
    #     "system-config-expert".enable = lib.mkDefault true;
    #     "rails-event-store-specialist".enable = lib.mkDefault true;
    #     "ethical-scraper".enable = lib.mkDefault true;
    #   };
    #
    #   commands = {
    #     "do".enable = lib.mkDefault true;
    #     "ask".enable = lib.mkDefault true;
    #     "implement-change".enable = lib.mkDefault true;
    #     "implement-feature".enable = lib.mkDefault true;
    #     "implement-fix".enable = lib.mkDefault true;
    #     "implement-refactoring".enable = lib.mkDefault true;
    #     "implement-tests".enable = lib.mkDefault true;
    #     "add-and-format".enable = lib.mkDefault true;
    #     "commit-changes".enable = lib.mkDefault true;
    #     "commit-msg".enable = lib.mkDefault true;
    #     "review".enable = lib.mkDefault true;
    #     "nix-check".enable = lib.mkDefault true;
    #     "flake-update".enable = lib.mkDefault true;
    #     "module-scaffold".enable = lib.mkDefault true;
    #     "option-migrate".enable = lib.mkDefault true;
    #     "refactor".enable = lib.mkDefault true;
    #     "template-new".enable = lib.mkDefault true;
    #     "changelog".enable = lib.mkDefault true;
    #     "deep-check".enable = lib.mkDefault true;
    #     "dependency-audit".enable = lib.mkDefault true;
    #     "module-lint".enable = lib.mkDefault true;
    #     "quick-check".enable = lib.mkDefault true;
    #     "style-audit".enable = lib.mkDefault true;
    #   };
    #
    #   mcp = {
    #     shadcn.enable = lib.mkDefault true;
    #     context7.enable = lib.mkDefault true;
    #     playwright.enable = lib.mkDefault true;
    #     "podman-mcp".enable = lib.mkDefault true;
    #     "chrome-devtools".enable = lib.mkDefault true;
    #     "mcp-nixos".enable = lib.mkDefault (!isDarwin);
    #   };
    # };

    users.users."${cfg.username}".packages = [
      pkgs.code-cursor
      pkgs.cursor-cli
      pkgs.goose-cli
    ];
  };
}
