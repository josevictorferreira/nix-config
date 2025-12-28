{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.programs.tmuxp;

  chat = {
    session_name = "chat";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "Chat";
        panes = [ "weechat" ];
      }
    ];
  };

  main = {
    session_name = "main";
    start_directory = "$HOME/.config/nix";
    windows = [
      {
        window_name = "NixConfig";
        layout = "main-vertical";
        panes = [
          "fastfetch"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "Neovim";
        start_directory = "$HOME/.config/nvim";
        panes = [
          "clear"
          "clear"
        ];
      }
    ];
  };

  monitoring = {
    session_name = "monitoring";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "System";
        panes = [
          "btop"
        ];
      }
      {
        window_name = "Cluster";
        panes = [
          "k9s"
        ];
      }
    ];
  };

  projectsHomelab = {
    session_name = "homelab";
    start_directory = "$HOME/Workspace/homelab";
    windows = [
      {
        window_name = "Homelab";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  projectsValoris = {
    session_name = "valoris";
    start_directory = "$HOME/Workspace/valoris";
    windows = [
      {
        window_name = "Valoris Main";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  projectsAiWorkspace = {
    session_name = "ai-workspace";
    start_directory = "$HOME/Workspace/ai-workspace";
    windows = [
      {
        window_name = "AI Workspace";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  work = {
    session_name = "work";
    start_directory = "$HOME/Workspace/agrosmart/";
    windows = [
      {
        window_name = "BoosterAgro";
        layout = "tiled";
        start_directory = "booster";
        panes = [
          "clear"
          "clear"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "Nexus";
        layout = "tiled";
        start_directory = "nexus/nexus-backend";
        panes = [
          "clear"
          "clear"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "BoosterPro";
        layout = "main-vertical";
        start_directory = "agrosmart-api";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };
in

{
  options.jvf.programs.tmuxp = {
    enable = lib.mkEnableOption "tmux, a terminal multiplexer";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };
    package = lib.mkPackageOption pkgs "tmuxp" { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        TMUXP_CONFIGDIR = "$HOME/.config/tmuxp";
      };
    };

    jvf.wrappers.users.${cfg.username}.programs.tmuxp = {
      packages = [
        pkgs.tmux
        pkgs.fastfetch
        cfg.package
      ];
      configs = {
        "chat.yaml" = chat;
        "main.yaml" = main;
        "monitoring.yaml" = monitoring;
        "homelab.yaml" = projectsHomelab;
        "valoris.yaml" = projectsValoris;
        "ai-workspace.yaml" = projectsAiWorkspace;
        "work.yaml" = work;
      };
    };
  };
}
