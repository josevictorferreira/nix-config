{ lib
, config
, system
, ...
}:

let
  cfg = config.jvf;
  # NOTE: uses `system` specialArg (not pkgs.stdenv.isDarwin) because
  # isDarwin is used in top-level config branching with optionalAttrs,
  # and pkgs requires config._module.args which creates infinite recursion.
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf = {
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              enable = lib.mkEnableOption "this user account";

              homeMode = lib.mkOption {
                type = lib.types.str;
                default = "755";
                description = "The mode for the user's home directory";
              };

              description = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "User description (e.g., full name)";
              };

              extraGroups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "networkmanager"
                  "wheel"
                  "libvirtd"
                  "scanner"
                  "lp"
                  "video"
                  "input"
                  "audio"
                ];
                description = "Extra groups for the user";
              };

              authorizedKeys = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "SSH authorized keys for the user";
              };

              packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "Packages installed for this user";
              };
            };
          }
        )
      );

      default = { };
      description = ''
        Attribute set of users to configure. Each attribute name is the username,
        and the value is the configuration for that user.
      '';
    };
  };

  config =
    { }
    // (lib.optionalAttrs (!isDarwin) {
      users.users = lib.mapAttrs
        (name: userCfg: {
          description = userCfg.description;
          openssh.authorizedKeys.keys = userCfg.authorizedKeys;
          packages = userCfg.packages;
          group = name;
          homeMode = userCfg.homeMode;
          extraGroups = userCfg.extraGroups;
          isNormalUser = true;
        })
        cfg.users;
      users.mutableUsers = true;
      users.groups = lib.mapAttrs (name: userCfg: lib.mkIf userCfg.enable { }) cfg.users;
    })
    // (lib.optionalAttrs isDarwin {
      users.users = lib.mapAttrs
        (name: userCfg: {
          description = userCfg.description;
          openssh.authorizedKeys.keys = userCfg.authorizedKeys;
          packages = userCfg.packages;
        })
        cfg.users;
    });
}
