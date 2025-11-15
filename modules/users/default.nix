{
  lib,
  config,
  ...
}:

let
  cfg = config.jvf.users;
in
{
  options.jvf.users = {
    enable = lib.mkEnableOption "jvf users module (enables multi-user configuration)";

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

  config = lib.mkIf cfg.enable {
    users.mutableUsers = true;

    users.users = lib.mapAttrs (
      name: userCfg:
      lib.mkIf userCfg.enable {
        homeMode = userCfg.homeMode;
        isNormalUser = true;
        description = userCfg.description;
        extraGroups = userCfg.extraGroups;
        openssh.authorizedKeys.keys = userCfg.authorizedKeys;
        packages = userCfg.packages;
      }
    ) cfg.users;
  };
}
