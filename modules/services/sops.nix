{ config
, lib
, inputs
, ...
}:
let
  inherit (inputs) self;
  cfg = config.jvf.services.sops;
in
{
  options.jvf.services.sops = {
    enable = lib.mkEnableOption "Enable sops encryption";
    ageKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "/etc/sops/age/keys.txt";
      description = "Path to the age key file used by sops";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = "${self}/secrets/secrets.enc.yaml";
      age.keyFile = cfg.ageKeyPath;
    };

    environment.variables.SOPS_AGE_KEY_FILE = cfg.ageKeyPath;
  };
}
