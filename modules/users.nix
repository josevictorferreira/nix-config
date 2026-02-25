# Aspect: users
# Defines jvf.users option (attrsOf submodule) and platform-specific user config.
# NixOS: full user management (groups, homeMode, extraGroups, isNormalUser).
# Darwin: lightweight user config (description, authorizedKeys, packages).
_:
let
  # Shared option definition — identical for both platforms
  mkUsersOption =
    { lib, ... }:
    {
      options.jvf.users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            _:
            {
              options = {
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
in
{
  flake.modules.nixos.users =
    { config, lib, ... }:
    let
      cfg = config.jvf;
    in
    {
      imports = [ mkUsersOption ];

      config = {
        users.users = lib.mapAttrs
          (name: userCfg: {
            inherit (userCfg) description;
            openssh.authorizedKeys.keys = userCfg.authorizedKeys;
            inherit (userCfg) packages;
            group = name;
            inherit (userCfg) homeMode;
            inherit (userCfg) extraGroups;
            isNormalUser = true;
          })
          cfg.users;
        users.mutableUsers = true;
        users.groups = lib.mapAttrs (_: _: { }) cfg.users;
      };
    };

  flake.modules.darwin.users =
    { config, lib, ... }:
    let
      cfg = config.jvf;
    in
    {
      imports = [ mkUsersOption ];

      config = {
        users.users = lib.mapAttrs
          (_: userCfg: {
            inherit (userCfg) description;
            openssh.authorizedKeys.keys = userCfg.authorizedKeys;
            inherit (userCfg) packages;
          })
          cfg.users;
      };
    };
}
