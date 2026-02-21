{ config
, lib
, inputs
, system
, ...
}:

let
  inherit (inputs) self;
  cfg = config.jvf.system.security;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.security = {
    enable = lib.mkEnableOption "system security configuration" // {
      description = ''
        Whether to enable system security configuration.
        Configures:
        - Realtime kernel scheduling support (rtkit)
        - Polkit for system-level permission management
        - SSH daemon for remote access
        - PAM services for security
      '';
    };

    enableSsh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SSH daemon for remote access.";
    };

    enableRtkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable RealtimeKit for realtime process scheduling.";
    };

    enablePolkit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable PolicyKit for privilege management.
        Configures custom rules for users group and wheel group.
      '';
    };

    enableGnomeKeyring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GNOME keyring for credential storage.";
    };

    enableFwupd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable firmware updates via fwupd.";
    };

    # SOPS options
    enableSops = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SOPS secret management with age encryption.";
    };

    sopsAgeKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "/etc/sops/age/keys.txt";
      description = "Path to the age key file used by sops";
    };
  };

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
      {
        security = {
          sudo.extraConfig = ''
            Defaults pwfeedback
          '';
          rtkit.enable = cfg.enableRtkit;
          polkit = lib.mkMerge [
            { enable = lib.mkDefault cfg.enablePolkit; }
            (lib.mkIf cfg.enablePolkit {
              extraConfig = ''
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
                });

                polkit.addRule(function(action, subject) {
                  if (subject.isInGroup("wheel") &&
                      action.id.indexOf("org.freedesktop.policykit.exec") >= 0) {
                    return polkit.Result.YES;
                  }
                });
              '';
            })
          ];
        };

        services.openssh = lib.mkIf cfg.enableSsh {
          enable = true;
        };

        services.gnome.gnome-keyring = lib.mkIf cfg.enableGnomeKeyring {
          enable = true;
        };

        security.pam.services.login = lib.mkIf cfg.enableGnomeKeyring {
          enableGnomeKeyring = true;
        };

        services.fwupd = lib.mkIf cfg.enableFwupd {
          enable = true;
        };

        services.seatd = lib.mkIf cfg.enablePolkit {
          enable = true;
        };

        sops = lib.mkIf cfg.enableSops {
          defaultSopsFile = "${self}/secrets/secrets.enc.yaml";
          age.keyFile = cfg.sopsAgeKeyPath;
        };

        environment.variables.SOPS_AGE_KEY_FILE = lib.mkIf cfg.enableSops cfg.sopsAgeKeyPath;
      }
    else
      {
        sops = lib.mkIf cfg.enableSops {
          defaultSopsFile = "${self}/secrets/secrets.enc.yaml";
          age.keyFile = cfg.sopsAgeKeyPath;
        };

        environment.variables.SOPS_AGE_KEY_FILE = lib.mkIf cfg.enableSops cfg.sopsAgeKeyPath;
      }
  );
}
