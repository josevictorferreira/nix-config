# Aspect: system-networking
# Defines jvf.system.networking options and platform-specific networking config.
# NixOS: networking.hostName + networkmanager.enable.
# Darwin: just networking.hostName (no NetworkManager).
_:
let
  mkNetworkingOptions =
    { lib, ... }:
    {
      options.jvf.system.networking = {
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
    };

  mkConfig =
    { isDarwin }:
    { config, ... }:
    let
      cfg = config.jvf.system.networking;
    in
    {
      imports = [ mkNetworkingOptions ];

      config =
        if (!isDarwin) then
          {
            networking = {
              inherit (cfg) hostName;
              networkmanager.enable = true;
            };
          }
        else
          {
            networking = {
              inherit (cfg) hostName;
            };
          };
    };
in
{
  flake.modules.nixos.system-networking = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-networking = mkConfig { isDarwin = true; };
}
