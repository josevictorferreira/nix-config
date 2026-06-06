# Aspect: programs-kitty
# Defines jvf.programs.kitty options and platform-specific kitty terminal config.
# NixOS: kitty package via wrappers + config via jvf.home + nerd-fonts.
# Darwin: kitty package via wrappers + config via jvf.home + nerd-fonts.
_:
let
  mkKittyOptions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.jvf.programs.kitty = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };

        package = lib.mkPackageOption pkgs "kitty" { };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = lib.mdDoc "Configuration for kitty, written to kitty.conf.";
          example = {
            font_size = 11;
            background_opacity = "1.0";
          };
        };
      };
    };

  toConfigFormat =
    lib: settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        if builtins.isBool value then
          "${key} ${if value then "yes" else "no"}"
        else
          "${key} ${toString value}"
      ) settings
    );

  kittyModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.kitty;

      tmuxpInitScript = pkgs.writeShellScriptBin "tmuxp-init" ''
        set -euo pipefail

        # Ensure we have a proper PATH on Darwin
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          # Additional common paths for nix-darwin
          export PATH="/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
          if [ -d "/etc/profiles/per-user/$USER/bin" ]; then
            export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
          fi
        ''}

        # Set TMUXP_CONFIGDIR explicitly as it's often missing in GUI environments
        export TMUXP_CONFIGDIR="$HOME/.config/tmuxp"

        # Ensure tmux and zsh are available in PATH for tmuxp
        export PATH="${
          lib.makeBinPath [
            pkgs.tmux
            pkgs.zsh
          ]
        }:$PATH"

        # Avoid nested tmux sessions if somehow launched from within tmux
        if [ -n "''${TMUX-}" ]; then
          exec ${lib.getExe pkgs.zsh}
        fi

        # Attempt to load the 'main' session.
        # We use a fallback to zsh to ensure the terminal remains usable if tmuxp fails.
        if ! ${lib.getExe pkgs.tmuxp} load -y main; then
          echo "Error: tmuxp failed to load 'main' session." >&2
          echo "Falling back to ${pkgs.zsh.name}..." >&2
          exec ${lib.getExe pkgs.zsh}
        fi
      '';

      defaultSettings = {
        bold_font = "JetBrainsMonoNL Nerd Font Bold";
        italic_font = "JetBrainsMonoNL Nerd Font Italic";
        bold_italic_font = "JetBrainsMonoNL Nerd Font Bold Italic";
        disable_ligatures = "never";
        window_border_width = "0.0pt";
        window_margin_width = 0;
        draw_minimal_borders = true;
        window_padding_width = 0;
        single_window_margin_width = -1;
        confirm_os_window_close = 0;
        placement_strategy = "top-left";
        repaint_delay = 2;
        input_delay = 0;
        sync_to_monitor = false;
        wayland_enable_ime = false;
        term = "xterm-256color";
        background_opacity = "0.95";
        shell = "${tmuxpInitScript}/bin/tmuxp-init";
        cursor_trail = 1;
        cursor_trail_decay = "0.1 0.2";
        cursor_trail_start_threshold = 4;
        allow_remote_control = "socket-only";
        listen_on = "unix:\${XDG_RUNTIME_DIR}/jvf-kitty-remote";
      };

      colorIndices = lib.genList lib.id 16;

      themeOverrides = {
        font_family = config.jvf.theme.fonts.monospace;
        font_size = config.jvf.theme.fonts.size;
        background = "#${config.jvf.theme.colors.background}";
        foreground = "#${config.jvf.theme.colors.foreground}";
        cursor = "#${config.jvf.theme.colors.cursor}";
        cursor_trail_color = "#${config.jvf.theme.colors.cursor}";
      }
      // lib.listToAttrs (
        map (
          i:
          lib.nameValuePair "color${toString i}" "#${lib.getAttr "color${toString i}" config.jvf.theme.colors}"
        ) colorIndices
      );
    in
    {
      imports = [ mkKittyOptions ];

      config = {
        jvf.programs.kitty.settings = lib.mkDefault (defaultSettings // themeOverrides);

        jvf.wrappers.users.${cfg.username}.programs.kitty = {
          packages = [
            cfg.package
          ];
        };

        jvf.home.users.${cfg.username}.items.".config/kitty/kitty.conf" = {
          kind = "file";
          mode = "copy";
          text = toConfigFormat lib cfg.settings;
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
in
{
  flake.modules.nixos.programs-kitty = kittyModule;
  flake.modules.darwin.programs-kitty = kittyModule;
}
