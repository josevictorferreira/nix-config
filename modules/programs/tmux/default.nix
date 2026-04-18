# Aspect: programs-tmux
# Defines jvf.programs.tmux and jvf.programs.tmuxp options.
# tmux: terminal multiplexer with vi keys, C-a prefix, mouse, plugins.
# tmuxp: session manager with picker script and 9 session configs.
_:
let
  # Import helpers as pure data/functions
  mkTmuxConf = import ./_/tmux-conf.nix;
  sessions = import ./_/sessions.nix;

  tmuxModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.tmux;
      tmuxpCfg = config.jvf.programs.tmuxp;

      # Generate tmux.conf using imported function
      tmuxConf = mkTmuxConf { inherit lib; } {
        inherit (cfg) plugins;
        colors = config.jvf.theme.colors;
      };

      # tmuxp sessions
      dynamicSessions = [ "valorisBackend" ];

      tmuxpPicker = pkgs.writeShellScriptBin "tmuxp-picker" ''
        set -euo pipefail

        TMUXP_DIR="''${TMUXP_CONFIGDIR:-$HOME/.config/tmuxp}"
        DYNAMIC_SESSIONS=(${lib.concatStringsSep " " dynamicSessions})

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
        for ds in "''${DYNAMIC_SESSIONS[@]}"; do
          if [ "$selected" = "$ds" ]; then
            is_dynamic=true
            break
          fi
        done

        if [ "$is_dynamic" = "true" ]; then
          # Find next available SESSION_ID by checking existing tmux sessions
          # Extract session IDs from existing sessions matching the pattern
          existing_ids=$(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' 2>/dev/null | \
            grep -oE 'Sandbox [0-9]+' | sed 's/Sandbox //' || echo "0")

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
      yamlFmt = pkgs.formats.yaml { };
      tmuxpConfigDir = pkgs.linkFarm "tmuxp-sessions" (
        lib.mapAttrsToList
          (
            name: session:
              let
                # Convert CamelCase to kebab-case for yaml filename (e.g. valorisBackend -> valoris-backend)
                yamlName = lib.removePrefix "-" (
                  lib.concatMapStrings (c: if c >= "A" && c <= "Z" then "-${lib.toLower c}" else c) (
                    lib.stringToCharacters name
                  )
                );
              in
              {
                name = "${yamlName}.yaml";
                path = yamlFmt.generate yamlName session;
              }
          )
          sessions
      );
    in
    {
      imports = [ ./options.nix ];

      config = lib.mkMerge [
        # tmux config
        {
          jvf = {
            wrappers.users.${cfg.username}.programs.tmux = {
              packages = [ cfg.package ];
            };
            home.users.${cfg.username}.items.".config/tmux/tmux.conf" = {
              kind = "file";
              mode = "copy";
              text = tmuxConf;
            };
          };
        }

        # tmuxp picker (available whenever tmux is enabled)
        {
          environment.systemPackages = [ tmuxpPicker ];
        }

        # tmuxp config
        (lib.mkIf tmuxpCfg.enable {
          environment = {
            variables = {
              TMUXP_CONFIGDIR = "$HOME/.config/tmuxp";
            };
          };

          jvf = {
            wrappers.users.${tmuxpCfg.username}.programs.tmuxp = {
              packages = [
                pkgs.tmux
                pkgs.fastfetch
                pkgs.fzf
                tmuxpCfg.package
              ];
            };
            home.users.${tmuxpCfg.username}.items.".config/tmuxp" = {
              kind = "dir";
              mode = "copy";
              source = tmuxpConfigDir;
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
