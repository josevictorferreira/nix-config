# Aspect: roles-base
# Fundamental system configuration every host needs.
# Enables: base-programs, base-services, environment, firewall, networking.
{ ... }:
let
  mkBaseOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.base = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable base system configuration.";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for configuration.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.jvf.roles.base;
    in
    {
      imports = [ mkBaseOptions ];

      config = lib.mkIf cfg.enable (
        {
          jvf.system.base-programs.enable = true;
          jvf.system.environment.enable = true;
        }
        // (
          if !isDarwin then
            {
              jvf.system.base-services.enable = true;
              jvf.system.firewall.enable = true;
              jvf.system.networking.enable = true;
              jvf.system.networking.hostName = config.jvf.core.host;
            }
          else
            {
              jvf.system.networking.enable = true;
              jvf.system.networking.hostName = config.jvf.core.host;
            }
        )
      );
    };
in
{
  flake.modules.nixos.roles-base = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-base = mkConfig { isDarwin = true; };
}
