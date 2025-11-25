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

    theme = lib.mkOption {
      type = lib.types.str;
      default = "cypher";
      description = "The oh-my-zsh theme to be loaded";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "git"
        "sudo"
        "kubectl"
        "aws"
        "postgres"
        "podman"
        "helm"
        "gh"
        "fluxcd"
        "docker"
        "docker-compose"
        "macos"
        "rsync"
        "ssh"
        "tmux"
        "vi-mode"
      ];
      description = "List of plugins to be loaded within zsh configuration";
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
          "openrouter_api_key_terminal"
          "openrouter_api_key_commit"
          "openrouter_api_key_autocomplete"
          "openrouter_api_key_code_agent"
          "context7_api_key"
          "github_token"
        ];
        description = "List of sops secret keys to expose";
      };
    };
  };
}
