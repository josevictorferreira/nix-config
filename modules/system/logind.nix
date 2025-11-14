{ config, lib, ... }:

let
  cfg = config.jvf.system.logind;
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

    allowUsersToDoPowerOperations = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow users to perform power operations like reboot/poweroff.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.logind.settings = {
      Login = {
        HandleLidSwitch = cfg.handleLidSwitch;
        HandleSuspendKey = cfg.handleSuspendKey;
        HandleHibernateKey = cfg.handleHibernateKey;
      };
    };

    security = lib.mkIf cfg.allowUsersToDoPowerOperations {
      polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (
            subject.isInGroup("users")
              && (
                action.id == "org.freedesktop.login1.reboot" ||
                action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                action.id == "org.freedesktop.login1.power-off" ||
                action.id == "org.freedesktop.login1.power-off-multiple-sessions"
              )
            )
          {
            return polkit.Result.YES;
          }
        })
      '';
    };
  };
}
