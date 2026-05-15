# Aspect: system-power-management
# Defines jvf.system.power-management options and platform-specific power config.
# NixOS: zram swap, CPU frequency governor, cpufrequtils package.
# Darwin: empty config (power management handled by macOS).
_:
let
  mkPowerManagementOptions =
    { config, lib, ... }:
    {
      options.jvf.system.power-management = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = ''
            Username of the user for whom power management optimizations should be applied.
          '';
        };

        zramAlgorithm = lib.mkOption {
          type = lib.types.enum [
            "zstd"
            "lz4"
            "lz4hc"
            "zle"
            "deflate"
            "842"
          ];
          default = "zstd";
          description = ''
            Compression algorithm to use for zram swap.
            "zstd" provides good compression ratio and speed.
          '';
        };

        zramMemoryPercent = lib.mkOption {
          type = lib.types.int;
          default = 30;
          description = ''
            Percentage of RAM to use for zram swap devices.
            30% is a reasonable value for systems with 16GB+ RAM.
          '';
        };

        zramPriority = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = ''
            Priority of zram swap devices (higher is preferred).
            100 makes zram preferred over disk swap.
          '';
        };

        cpuFreqGovernor = lib.mkOption {
          type = lib.types.enum [
            "schedutil"
            "powersave"
            "performance"
            "ondemand"
          ];
          default = "schedutil";
          description = ''
            CPU frequency scaling governor.
            "schedutil" provides good balance of performance and power efficiency.
          '';
        };
      };
    };

  nixosModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.system.power-management;
    in
    {
      imports = [ mkPowerManagementOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.cpufrequtils
        ];

        zramSwap = {
          enable = true;
          priority = cfg.zramPriority;
          memoryPercent = cfg.zramMemoryPercent;
          swapDevices = 1;
          algorithm = cfg.zramAlgorithm;
        };

        systemd.services."systemd-zram-setup@zram0".restartIfChanged = false;

        powerManagement = {
          enable = true;
          inherit (cfg) cpuFreqGovernor;
        };
      };
    };
in
{
  flake.modules.nixos.system-power-management = nixosModule;
}
