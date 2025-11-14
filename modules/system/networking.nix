{
  config,
  lib,
  ...
}:

let
  cfg = config.jvf.system.networking;
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
      networkmanager.enable = true;
      timeServers = 
        if cfg.manageTime 
        then (lib.attrByPath [ "networking" "timeServers" "default" ] [] options) ++ cfg.additionalTimeServers
        else lib.attrByPath [ "networking" "timeServers" "default" ] [] options;
    };
  };
}
