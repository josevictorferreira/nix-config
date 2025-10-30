{ lib
, pkgs
, config
, username
, isDarwin
, isNixOS
, jvfLib
, ...
}:
let
  cfg = config.jvf.programs.easyeffects;
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
      mkdir -p $out/share/easyeffects-config
      cp -r . $out/share/easyeffects-config/
    '';

    meta = with lib; {
      description = "EasyEffects configuration for josevictorferreira";
      homepage = "https://github.com/josevictorferreira/.easyeffects";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  setupEasyEffectsConfig = jvfLib.filesystem.createConfigLinks {
    derivation = easyeffectsConfigDerivation;
    configPath = "/share/easyeffects-config";
    targetDir = "easyeffects";
    username = cfg.username;
    inherit isDarwin;
    description = "EasyEffects configuration";
  };
in
{
  options.jvf.programs.easyeffects = {
    enable = lib.mkEnableOption "easyeffects, an audio effects pipeline for PipeWire";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the easyeffects configuration";
    };
    useDerivationConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the derivation-based easyeffects configuration from GitHub";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.easyeffects
    ]
    ++ lib.optionals cfg.useDerivationConfig [
      easyeffectsConfigDerivation
    ];

    systemd.services.setup-easyeffects-config = lib.mkIf (cfg.useDerivationConfig && isNixOS) {
      description = "Setup EasyEffects configuration from derivation";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = "${setupEasyEffectsConfig}";
      };
    };

    system.activationScripts.setup-easyeffects-config = lib.mkIf cfg.useDerivationConfig ''
      echo "Setting up EasyEffects configuration..."
      ${setupEasyEffectsConfig}
    '';
  };
}
