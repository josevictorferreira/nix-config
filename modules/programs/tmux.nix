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
    sha256 = "sha256-mqEid7pBC72tebfGE/oy/CQ37d0HHjC9qtTsn8QbsqM=";
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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.tmuxp
      tmuxWrapper
    ]
    ++ lib.optionals cfg.useDerivationConfig [
      tmuxConfigDerivation
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

    environment.etc."tmux.conf".text = builtins.readFile tmuxConf;
  };
}
