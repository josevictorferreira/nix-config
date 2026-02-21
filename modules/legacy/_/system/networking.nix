{ config
, lib
, system
, ...
}:

let
  cfg = config.jvf.system.networking;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.networking = {
    enable = lib.mkEnableOption "basic networking configuration" // {
      description = ''
        Whether to enable basic networking configuration.
        Configures:
        - NetworkManager (primary network management)
        - NTP time synchronization
      '';
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "The hostname of the system.";
    };

    manageTime = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to configure time synchronization settings.";
    };

    additionalTimeServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "pool.ntp.org" ];
      description = "Additional NTP time servers to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      hostName = cfg.hostName;
    }
    // lib.optionalAttrs (!isDarwin) {
      networkmanager.enable = true;
    };
  };
}
