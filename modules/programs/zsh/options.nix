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
          "minimax_api_key"
          "context7_api_key"
          "github_token"
          "hugging_face_api_key"
          "civitai_api_key"
          "gemini_api_key"
          "google_generative_ai_api_key"
          "z_ai_api_key"
          "kimi_api_key"
          "grafana_url"
          "grafana_username"
          "grafana_password"
          "grafana_service_account_token"
          "homelab_postgres_username"
          "homelab_postgres_password"
          "valoris_secret_key"
        ];
        description = "List of sops secret keys to expose";
      };
    };
  };
}
