# Aspect: system-environment
# Defines jvf.system.environment options for global environment variables.
# Same config for both NixOS and Darwin.
_:
let
  mkEnvironmentOptions =
    { lib, ... }:
    {
      options.jvf.system.environment = {
        steamExtraCompatToolsPath = lib.mkOption {
          type = lib.types.str;
          default = "$HOME/.steam/root/compatibilitytools.d";
          description = "Path for Steam compatibility tools.";
        };

        xdgConfigHome = lib.mkOption {
          type = lib.types.str;
          default = "$HOME/.config";
          description = "Base directory for user-specific XDG configuration files.";
        };

        nixosOzoneWl = lib.mkOption {
          type = lib.types.str;
          default = "1";
          description = "Enable Ozone-Wayland support for NixOS applications.";
        };
      };
    };

  environmentModule =
    { config, ... }:
    let
      cfg = config.jvf.system.environment;
    in
    {
      imports = [ mkEnvironmentOptions ];

      config = {
        environment = {
          variables = {
            STEAM_EXTRA_COMPAT_TOOLS_PATHS = cfg.steamExtraCompatToolsPath;
            XDG_CONFIG_HOME = cfg.xdgConfigHome;
            NIXOS_OZONE_WL = cfg.nixosOzoneWl;
          };
        };
      };
    };
in
{
  flake.modules.nixos.system-environment = environmentModule;
  flake.modules.darwin.system-environment = environmentModule;
}
