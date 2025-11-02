{ lib
, pkgs
, config
, jvfLib
, ...
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
    ];
  };

  monitoring = {
    session_name = "monitoring";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "Cluster";
        panes = [
          "k9s"
          "btop"
        ];
      }
    ];
  };

  projects = {
    session_name = "projects";
    start_directory = "$HOME/Workspace/";
    windows = [
      {
        window_name = "Homelab";
        layout = "tiled";
        start_directory = "homelab-reborn";
        panes = [
          "clear"
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

  tmuxpConfigs = {
    "chat.yaml" = chat;
    "main.yaml" = main;
    "monitoring.yaml" = monitoring;
    "projects.yaml" = projects;
    "work.yaml" = work;
  };

  tmuxpSessionsDir = jvfLib.filesystem.mkConfigDir "tmuxp-sessions" tmuxpConfigs;

  tmuxpPackage = (
    pkgs.symlinkJoin {
      name = "tmuxp-base";
      buildInputs = [ pkgs.makeWrapper ];
      paths = [
        pkgs.tmuxp
      ];
      postBuild = ''
        cat > $out/bin/tmuxp-init << 'EOF'
        #!/usr/bin/env bash
        set -euo pipefail

        # Change to the sessions directory
        cd "${tmuxpSessionsDir}" || exit 1

        ${pkgs.tmuxp}/bin/tmuxp load -y monitoring.yaml chat.yaml work.yaml projects.yaml main.yaml

        echo "All tmuxp sessions initialized!"
        EOF

        chmod +x $out/bin/tmuxp-init

        wrapProgram $out/bin/tmuxp
      '';
    }
  );
in

{
  options.jvf.programs.tmuxp = {
    enable = lib.mkEnableOption "tmux, a terminal multiplexer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      tmuxpPackage
    ];
  };
}
