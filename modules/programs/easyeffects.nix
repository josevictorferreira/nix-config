{ lib
, pkgs
, config
, username
, isNixOS
, jvfLib
, ...
}:
let
  cfg = config.jvf.programs.easyeffects;

  userHome = config.users.users.${cfg.username}.home or "/home/${username}";
  group = config.users.users.${username}.group or "users";

  easyeffectsConfig = pkgs.fetchFromGitHub {
    owner = "josevictorferreira";
    repo = ".easyeffects";
    rev = "main";
    sha256 = "sha256-hN8xUCujOn5+y1SiBjQIvxs2ewGcZhtiHoUWIS1GpIY=";
  };

  easyeffectsConfigDerivation = pkgs.stdenv.mkDerivation {
    pname = "josevictor-easyeffects-config";
    version = "1.0.0";

    src = easyeffectsConfig;

    installPhase = ''
      mkdir -p $out/share/easyeffects
      cp -r . $out/share/easyeffects
    '';

    meta = with lib; {
      description = "EasyEffects configuration for josevictorferreira";
      homepage = "https://github.com/josevictorferreira/.easyeffects";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  setupEasyeffectsConfig = jvfLib.filesystem.createConfigLinks {
    derivation = easyeffectsConfigDerivation;
    configtargetDir = "/share/easyeffects";
    targetDir = "easyeffects";
    username = cfg.username;
    isDarwin = false;
    description = "Easyeffects configuration and custom presets";
  };
in
{
  options.jvf.programs.easyeffects = {
    enable = lib.mkEnableOption "easyeffects, an audio effects pipeline for PipeWire";
    useDerivationConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the derivation-based easyeffects configuration from GitHub";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.easyeffects
    ];

    systemd.services.setup-easyeffects-config = lib.mkIf (isNixOS && cfg.useDerivationConfig) {
      description = "Setup Easyeffects configuration from derivation";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.username;
        ExecStart = "${setupEasyeffectsConfig}";
      };
    };

    system.userActivationScripts.setup-easyeffects-config = jvfLib.filesystem.cloneRepositoryOnce {
      username = cfg.username;
      group = group;
      repo = "git@github.com:josevictorferreira/.easyeffects.git";
      targetDir = "${userHome}/.config/easyeffects";
    };
  };
}
