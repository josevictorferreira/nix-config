# Aspect: system-environment
# Defines jvf.system.environment options for global environment variables.
# Same config for both NixOS and Darwin.
{ ... }:
let
  mkEnvironmentOptions =
    { lib, ... }:
    {
      options.jvf.system.environment = {
        enable = lib.mkEnableOption "environment variables configuration" // {
          description = ''
            Whether to enable environment variables configuration.
            Sets commonly used XDG and application-specific environment variables.
          '';
        };

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

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.environment;
    in
    {
      imports = [ mkEnvironmentOptions ];

      config = lib.mkIf cfg.enable {
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
  flake.modules.nixos.system-environment = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-environment = mkConfig { isDarwin = true; };
}
