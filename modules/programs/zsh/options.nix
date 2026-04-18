# options.nix - ZSH shell option definitions
{ config, lib, ... }:
{
  options.jvf.programs.zsh = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for zsh configuration";
    };

    setAsDefaultShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set zsh as default shell";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "agnoster";
      description = "Oh My Zsh theme to use";
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
      description = "List of Oh My Zsh plugins to load";
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

  };
}
