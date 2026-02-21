# Aspect: desktop-hyprland (NixOS only)
# Imports the Hyprland desktop module tree from legacy location.
# Host config sets jvf.desktop.hyprland.enable = true to activate.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland = {
    imports = [ ../legacy/_/desktop/hyprland ];
  };
}
