# Aspect: system-base-services
# Defines jvf.system.base-services options and platform-specific service config.
# NixOS: dbus, udev, libinput, envfs, gvfs, tumbler, smartd, lorri, fstrim.
# Darwin: empty config (no system services needed).
_:
let
  mkBaseServicesOptions =
    { lib, ... }:
    {
      options.jvf.system.base-services = {
        enableGvfs = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GVFS for virtual filesystem support.";
        };

        enableTumbler = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable thumbnail generation service.";
        };

        enableSmartd = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable SMART disk monitoring.";
        };

        enableLorri = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Lorri for automatic flake development environments.";
        };

        enableFstrim = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable periodic TRIM for SSDs.";
        };

        fstrimInterval = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          description = "Interval for SSD TRIM operations.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.base-services;
    in
    {
      imports = [ mkBaseServicesOptions ];

      config =
        if (!isDarwin) then
          {
            services = {
              dbus.enable = true;
              udev.enable = true;
              libinput.enable = true;
              envfs.enable = true;

              gvfs = lib.mkIf cfg.enableGvfs {
                enable = true;
              };

              tumbler.enable = lib.mkIf cfg.enableTumbler true;

              smartd = lib.mkIf cfg.enableSmartd {
                enable = true;
                autodetect = true;
              };

              lorri.enable = lib.mkIf cfg.enableLorri true;

              fstrim = lib.mkIf cfg.enableFstrim {
                enable = true;
                interval = cfg.fstrimInterval;
              };
            };
          }
        else
          { };
    };
in
{
  flake.modules.nixos.system-base-services = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-base-services = mkConfig { isDarwin = true; };
}
