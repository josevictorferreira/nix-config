# Aspect: system-logind
# Defines jvf.system.logind options and platform-specific session config.
# NixOS: services.logind.settings for lid switch and power key handling.
# Darwin: empty config (logind not available on macOS).
{ ... }:
let
  powerActionType =
    lib:
    lib.types.enum [
      "ignore"
      "poweroff"
      "reboot"
      "halt"
      "kexec"
      "suspend"
      "hibernate"
      "hybrid-sleep"
      "lock"
    ];

  mkLogindOptions =
    { lib, ... }:
    {
      options.jvf.system.logind = {
        enable = lib.mkEnableOption "logind configuration" // {
          description = ''
            Whether to enable logind configuration for power management and session handling.
            Configures:
            - Lid switch behavior
            - Power/suspend key handling
            - Allow regular users to perform power operations
          '';
        };

        handleLidSwitch = lib.mkOption {
          type = powerActionType lib;
          default = "lock";
          description = "Action to take when laptop lid is closed.";
        };

        handleSuspendKey = lib.mkOption {
          type = powerActionType lib;
          default = "lock";
          description = "Action to take when suspend key is pressed.";
        };

        handleHibernateKey = lib.mkOption {
          type = powerActionType lib;
          default = "lock";
          description = "Action to take when hibernate key is pressed.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.logind;
    in
    {
      imports = [ mkLogindOptions ];

      config = lib.mkIf cfg.enable (
        if (!isDarwin) then
          {
            services.logind.settings = {
              Login = {
                HandleLidSwitch = cfg.handleLidSwitch;
                HandleSuspendKey = cfg.handleSuspendKey;
                HandleHibernateKey = cfg.handleHibernateKey;
              };
            };
          }
        else
          { }
      );
    };
in
{
  flake.modules.nixos.system-logind = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-logind = mkConfig { isDarwin = true; };
}
