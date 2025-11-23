{ lib, username, ... }:

{
  options.jvf.programs.zsh = {
    enable = lib.mkEnableOption "zsh with advanced features";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for zsh configuration";
    };

    setAsDefaultShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set zsh as default shell";
    };

    features = {
      aiCommit = lib.mkEnableOption "AI-powered git commit messages";
      aiCommand = lib.mkEnableOption "AI command suggestions";
      advancedHistory = lib.mkEnableOption "Advanced history search with fzf";
      viMode = lib.mkEnableOption "Vi mode keybindings";
      powerLevel10k = lib.mkEnableOption "PowerLevel10k prompt";
      workAliases = lib.mkEnableOption "Work-specific aliases (Agrosmart)";
    };

    workspace = {
      root = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Workspace";
        description = "Root workspace directory";
      };

      shared = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Homelab";
        description = "Shared/homelab directory";
      };

      projects = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Project-specific paths";
        example = {
          agrosmart = "~/Workspace/agrosmart";
        };
      };
    };

    secrets = {
      keys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "openrouter_terminal"
          "openrouter_commit"
          "openrouter_autocomplete"
          "openrouter_code_agent"
          "context7_api_key"
          "github_token"
        ];
        description = "List of sops secret keys to expose";
      };
    };
  };
}
