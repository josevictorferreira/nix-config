{
  config,
  lib,
  system,
  ...
}:

let
  cfg = config.jvf.system.base-services;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.base-services = {
    enable = lib.mkEnableOption "base system services" // {
      description = ''
        Whether to enable common base system services.
        Configures:
        - Lorri (auto-evaluate dev shells)
        - D-Bus for inter-process communication
        - Udev for device management
        - Smart disk monitoring (disabled by default)
        - Envirfs for fast environment variable reloading
        - GVFS for virtual filesystem access
        - Thumbnail generation
      '';
    };

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
      description = "Interval for SSD TRIM operations. ";
    };
  };

  config = lib.mkIf cfg.enable (
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
      { }
  );
}
