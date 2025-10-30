{
  lib,
  pkgs,
  config,
  username,
  isDarwin,
  isNixOS,
  jvfLib,
  ...
}:
let
  cfg = config.jvf.programs.tmux;
  tmuxConfig = pkgs.fetchFromGitHub {
    owner = "josevictorferreira";
    repo = ".tmux";
    rev = "main";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  tmuxConfigDerivation = pkgs.stdenv.mkDerivation {
    pname = "josevictor-tmux-config";
    version = "1.0.0";

    src = tmuxConfig;

    installPhase = ''
      mkdir -p $out/share/tmux-config
      cp -r . $out/share/tmux-config/
    '';

    meta = with lib; {
      description = "Tmux configuration for josevictorferreira";
      homepage = "https://github.com/josevictorferreira/.tmux";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  setupTmuxConfig = jvfLib.filesystem.createConfigLinks {
    derivation = tmuxConfigDerivation;
    configPath = "/share/tmux-config";
    targetDir = "tmux";
    username = cfg.username;
    inherit isDarwin;
    description = "Tmux configuration";
  };

  tmuxConf = pkgs.writeText "tmux.conf" ''
    ${builtins.readFile "${tmuxConfigDerivation}/share/tmux-config/tmux.conf"}

    # Plugin configurations
    ${lib.concatStringsSep "\n" (
      map (plugin: if lib.isAttrs plugin then plugin.extraConfig else "") cfg.plugins
    )}
  '';

  tmuxWrapper = pkgs.writeScriptBin "tmux" ''
    #!${pkgs.bash}/bin/bash
    export TMUXP_CONFIGDIR="$HOME/.config/tmux/tmuxp"

    # Use our custom tmux.conf
    export TMUX_CONF="${tmuxConf}"

    # Call the actual tmux with our configuration
    exec ${pkgs.tmux}/bin/tmux -f "''${TMUX_CONF}" "$@"
  '';
in
{
  options.jvf.programs.tmux = {
    enable = lib.mkEnableOption "tmux, a terminal multiplexer";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the tmux configuration";
    };
    useDerivationConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the derivation-based tmux configuration from GitHub";
    };

    newSession = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to start a new session by default";
    };
    baseIndex = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Base index for windows and panes";
    };
    shell = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.zsh}/bin/zsh";
      description = "Default shell for tmux";
    };
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "tmux-256color";
      description = "Terminal type for tmux";
    };
    keyMode = lib.mkOption {
      type = lib.types.str;
      default = "vi";
      description = "Key binding mode (vi or emacs)";
    };
    mouse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable mouse support";
    };
    clock24 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use 24-hour clock format";
    };
    focusEvents = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable focus events";
    };
    historyLimit = lib.mkOption {
      type = lib.types.int;
      default = 10000;
      description = "Maximum lines in scrollback buffer";
    };
    escapeTime = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Time to wait for escape sequences";
    };
    aggressiveResize = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable aggressive resize";
    };
    plugins = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = with pkgs.tmuxPlugins; [
        yank
        sensible
        {
          plugin = tokyo-night-tmux;
          extraConfig = ''
            set -g @tokyo-night-tmux_theme storm
            set -g @tokyo-night-tmux_transparent 1
            set -g @tokyo-night-tmux_window_id_style digital
            set -g @tokyo-night-tmux_pane_id_style hsquare
            set -g @tokyo-night-tmux_zoom_id_style dsquare
          '';
        }
      ];
      description = "List of tmux plugins to install";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.tmux
      pkgs.tmuxp
      tmuxWrapper
    ]
    ++ lib.optionals cfg.useDerivationConfig [
      tmuxConfigDerivation
    ]
    ++ lib.optionals (!isNixOS) [
      (pkgs.writeScriptBin "setup-tmux-user" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        USER_HOME="$HOME"
        TMUX_DIR="''${USER_HOME}/.config/tmux"

        # Create tmux config directory
        mkdir -p "''${TMUX_DIR}"

        # Create tmuxp directory
        mkdir -p "''${TMUX_DIR}/tmuxp"

        # Link tmux.conf if it doesn't exist
        if [ ! -f "''${USER_HOME}/.tmux.conf" ]; then
          ln -sf ${tmuxConf} "''${USER_HOME}/.tmux.conf"
        fi

        echo "User tmux configuration setup completed"
      '')
    ];

    environment.variables = {
      TMUXP_CONFIGDIR = "$HOME/.config/tmux/tmuxp";
    };

    systemd.services.setup-tmux-config = lib.mkIf (cfg.useDerivationConfig && isNixOS) {
      description = "Setup Tmux configuration from derivation";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = "${setupTmuxConfig}";
      };
    };

    system.activationScripts.setup-tmux-config = lib.mkIf cfg.useDerivationConfig ''
      echo "Setting up Tmux configuration..."
      ${setupTmuxConfig}
    '';

    # Create tmux configuration for all users
    environment.etc."tmux.conf".text = builtins.readFile tmuxConf;

    # Create user-specific tmux configuration directory
    systemd.services.setup-user-tmux-config = lib.mkIf (cfg.useDerivationConfig && isNixOS) {
      description = "Setup user Tmux configuration";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeScript "setup-user-tmux" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          USER_HOME=${if isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}"}
          TMUX_DIR="$USER_HOME/.config/tmux"

          # Create tmux config directory
          mkdir -p "$TMUX_DIR"

          # Create tmuxp directory
          mkdir -p "$TMUX_DIR/tmuxp"

          # Link tmux.conf if it doesn't exist
          if [ ! -f "$USER_HOME/.tmux.conf" ]; then
            ln -sf ${tmuxConf} "$USER_HOME/.tmux.conf"
          fi

          # Set proper ownership
          ${lib.optionalString (!isDarwin) "chown -R ${cfg.username}:users \"$TMUX_DIR\""}
          ${lib.optionalString (!isDarwin) "chown ${cfg.username}:users \"$USER_HOME/.tmux.conf\""}

          echo "User tmux configuration setup completed"
        '';
      };
    };
  };
}
