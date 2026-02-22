# Aspect: desktop-hyprland-fastfetch (NixOS only)
# Fastfetch settings for Hyprland.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-fastfetch =
    { config, lib, ... }:
    let
      cfg = config.jvf.desktop.hyprland.fastfetch;
    in
    {
      options.jvf.desktop.hyprland.fastfetch = {
        enable = lib.mkEnableOption "Fastfetch hyprland and nixos settings.";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to configure fastfetch";
        };
      };

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.fastfetch = {
          packages = [ ];
          configs = {
            fastfetch = ../assets/desktop/fastfetch;
          };
        };
      };
    };
}
