# Aspect: programs-tmux
# Defines jvf.programs.tmux and jvf.programs.tmuxp options.
# tmux: terminal multiplexer with vi keys, C-a prefix, mouse, plugins.
# tmuxp: session manager with picker script and 9 session configs.
{ ... }:
let
  mkTmuxOptions =
    { config, lib, pkgs, ... }:
    let
      defaultPlugins = [
        pkgs.tmuxPlugins.yank
        pkgs.tmuxPlugins.onedark-theme
      ];
    in
    {
      options.jvf.programs.tmux = {
        enable = lib.mkEnableOption "tmux, a terminal multiplexer";
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };
        package = lib.mkPackageOption pkgs "tmux" { };
        plugins = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = defaultPlugins;
          description = "List of tmux plugins to install.";
        };
      };
    };

  mkTmuxpOptions =
    { config, lib, pkgs, ... }:
    {
      options.jvf.programs.tmuxp = {
        enable = lib.mkEnableOption "tmuxp, a tmux session manager";
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };
        package = lib.mkPackageOption pkgs "tmuxp" { };
      };
    };

  tmuxModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.tmux;
      tmuxpCfg = config.jvf.programs.tmuxp;

      applyPlugin = p: "run-shell ${if lib.types.package.check p then p.rtp else p.plugin.rtp}";

      tmuxConf = ''
        unbind C-b
        set-option -g prefix C-a
        bind-key C-a send-prefix
        bind a send-prefix

        set -g base-index 1

        set -g mouse on

        set -g pane-base-index 1

        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",tmux-256color:RGB"
        # Fix for ghost characters with Nerd Fonts and powerline symbols
        # Ensures proper width calculation across different terminals (ghostty, kitty, alacritty)
        set -ag terminal-overrides ",xterm-256color:RGB"
        set -g default-command "zsh"

        set -g history-limit 10000

        setw -g mode-keys vi
        set -g status-keys vi

        bind -T copy-mode-vi v send -X begin-selection
        bind P paste-buffer
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xsel -i -p && xsel -o -p | xsel -i -b"

        bind - split-window -v -c "#{pane_current_path}"
        bind = split-window -h -c "#{pane_current_path}"
        bind-key -r J resize-pane -D 5
        bind-key -r K resize-pane -U 5
        bind-key -r H resize-pane -L 5
        bind-key -r L resize-pane -R 5
        bind-key -r C-j resize-pane -D
        bind-key -r C-k resize-pane -U
        bind-key -r C-h resize-pane -L
        bind-key -r C-l resize-pane -R
        unbind '"'
        unbind %

        bind : command-prompt

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        set -g status-justify left
        set -g status-interval 2

        set -g status-left '''

        set-option -g visual-activity off
        set-option -g visual-bell off
        set-option -g visual-silence off
        set-window-option -g monitor-activity off
        set-option -g bell-action none
        set-option -g focus-events on
        set-option -g escape-time 0

        bind x kill-pane
        bind X next-layout
        bind Z previous-layout

        bind -n S-down new-window
        bind -n S-left prev
        bind -n S-right next
        bind -n C-left swap-window -t -1
        bind -n C-right swap-window -t +1

        # tmuxp session picker (prefix + t, replaces default time display)
        bind t display-popup -E -w 60% -h 60% "tmuxp-picker"

        set -g status-position bottom
        set -g status-left '''
        set -g status-right-length 50
        set -g status-left-length 20

        setw -g aggressive-resize on
        setw -g allow-rename off
        set -g set-clipboard on
        setw -g @shell_mode 'vi'

        ${lib.strings.concatStringsSep "\n" (map applyPlugin cfg.plugins)}
      '';

      # tmuxp sessions
      dynamicSessions = [ "valoris-backend" ];

      tmuxpPicker = pkgs.writeShellScriptBin "tmuxp-picker" ''
        set -euo pipefail

        TMUXP_DIR="''${TMUXP_CONFIGDIR:-$HOME/.config/tmuxp}"
        DYNAMIC_SESSIONS="${lib.concatStringsSep " " dynamicSessions}"

        if [ ! -d "$TMUXP_DIR" ]; then
          echo "tmuxp config directory not found: $TMUXP_DIR" >&2
          exit 1
        fi

        # List available sessions (strip .yaml extension)
        sessions=$(find "$TMUXP_DIR" -maxdepth 1 -name "*.yaml" -type f 2>/dev/null | xargs -n1 basename | sed 's/\.yaml$//' | sort)

        if [ -z "$sessions" ]; then
          echo "No tmuxp sessions found in $TMUXP_DIR" >&2
          exit 1
        fi

        # Use fzf to select a session
        selected=$(echo "$sessions" | ${lib.getExe pkgs.fzf} \
          --prompt="tmuxp session> " \
          --height=40% \
          --reverse \
          --border \
          --header="Select a tmuxp session to load")

        if [ -z "$selected" ]; then
          exit 0
        fi

        # Check if this is a dynamic session
        is_dynamic=false
        for ds in $DYNAMIC_SESSIONS; do
          if [ "$selected" = "$ds" ]; then
            is_dynamic=true
            break
          fi
        done

        if [ "$is_dynamic" = "true" ]; then
          # Find next available SESSION_ID by checking existing tmux sessions
          # Extract session IDs from existing sessions matching the pattern
          existing_ids=$(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' 2>/dev/null | \
            grep -oP '(?<=Sandbox )\d+$' || echo "0")

          # Find the maximum ID and add 1
          max_id=0
          for id in $existing_ids; do
            if [ "$id" -gt "$max_id" ]; then
              max_id=$id
            fi
          done
          export SESSION_ID=$((max_id + 1))

          echo "Starting $selected with SESSION_ID=$SESSION_ID"
          sleep 1
        fi

        # Load session (tmuxp will attach or switch automatically when inside tmux)
        exec ${lib.getExe tmuxpCfg.package} load -y "$selected"
      '';

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
        start_directory = "$HOME/.config/nix";
        windows = [
          {
            window_name = "Monitors";
            panes = [
              "btop"
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

      valorisBackend = {
        session_name = "Valoris - Backend Sandbox $SESSION_ID";
        start_directory = "$HOME/Workspace/valoris";
        windows = [
          {
            window_name = "Sandbox $SESSION_ID";
            layout = "tiled";
            panes = [
              "./bin/dev_sandbox backend $SESSION_ID"
              "sleep 3 && ./bin/dev_sandbox backend $SESSION_ID"
              "sleep 6 && ./bin/dev_sandbox backend $SESSION_ID"
            ];
          }
        ];
      };

      valorisFrontend = {
        session_name = "Valoris - Frontend";
        start_directory = "$HOME/Workspace/valoris/frontend";
        windows = [
          {
            window_name = "Valoris Frontend";
            layout = "tiled";
            panes = [
              "nix develop"
              "sleep 2 && nix develop"
              "sleep 4 && nix develop"
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
      imports = [
        mkTmuxOptions
        mkTmuxpOptions
      ];

      config = lib.mkMerge [
        # tmux config
        (lib.mkIf cfg.enable {
          jvf.wrappers.users.${cfg.username}.programs.tmux = {
            packages = [
              cfg.package
            ];
            configs = {
              "tmux.conf" = tmuxConf;
            };
          };

          jvf.programs.tmuxp.enable = true;
        })

        # tmuxp config
        (lib.mkIf tmuxpCfg.enable {
          environment = {
            variables = {
              TMUXP_CONFIGDIR = "$HOME/.config/tmuxp";
            };
          };

          jvf.wrappers.users.${tmuxpCfg.username}.programs.tmuxp = {
            packages = [
              pkgs.tmux
              pkgs.fastfetch
              pkgs.fzf
              tmuxpCfg.package
              tmuxpPicker
            ];
            configs = {
              "chat.yaml" = chat;
              "main.yaml" = main;
              "monitoring.yaml" = monitoring;
              "homelab.yaml" = projectsHomelab;
              "valoris.yaml" = projectsValoris;
              "valoris-backend.yaml" = valorisBackend;
              "valoris-frontend.yaml" = valorisFrontend;
              "ai-workspace.yaml" = projectsAiWorkspace;
              "work.yaml" = work;
            };
          };
        })
      ];
    };
in
{
  flake.modules.nixos.programs-tmux = tmuxModule;
  flake.modules.darwin.programs-tmux = tmuxModule;
}
