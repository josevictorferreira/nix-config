{ config
, lib
, system
, ...
}:

let
  cfg = config.jvf.system.logind;
  isDarwin = builtins.match ".*-darwin" system != null;
in
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
      type = lib.types.enum [
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
      default = "lock";
      description = "Action to take when laptop lid is closed.";
    };

    handleSuspendKey = lib.mkOption {
      type = lib.types.enum [
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
      default = "lock";
      description = "Action to take when suspend key is pressed.";
    };

    handleHibernateKey = lib.mkOption {
      type = lib.types.enum [
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
      default = "lock";
      description = "Action to take when hibernate key is pressed.";
    };
  };

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
}
