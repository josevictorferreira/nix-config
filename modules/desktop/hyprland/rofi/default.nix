{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.hyprland.rofi;
  configDir = config.xdg.configHome + "/rofi";
in
{
  options.modules.desktop.hyprland.rofi = {
    enable = mkEnableOption "rofi";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rofi-wayland
    ];

    xdg.configFile = {
      "rofi/config.rasi".text = import ./config/main.nix { inherit config pkgs; };
      "rofi/master-config.rasi".text = import ./config/master.nix { inherit config pkgs; };
      "rofi/config-calc.rasi".text = import ./config/calc.nix { inherit config pkgs; };
      "rofi/config-clipboard.rasi".text = import ./config/clipboard.nix { inherit config pkgs; };
      "rofi/config-compact.rasi".text = import ./config/compact.nix { inherit config pkgs; };
      "rofi/config-emoji.rasi".text = import ./config/emoji.nix { inherit config pkgs; };
      "rofi/config-keybinds.rasi".text = import ./config/keybinds.nix { inherit config pkgs; };
      "rofi/config-rofi-Beats-menu.rasi".text = import ./config/rofi-beats-menu.nix {
        inherit config pkgs;
      };
      "rofi/config-rofi-Beats.rasi".text = import ./config/rofi-beats.nix { inherit config pkgs; };
      "rofi/config-search.rasi".text = import ./config/search.nix { inherit config pkgs; };
      "rofi/config-wallpaper-effect.rasi".text = import ./config/wallpaper-effect.nix {
        inherit config pkgs;
      };
      "rofi/config-wallpaper.rasi".text = import ./config/wallpaper.nix { inherit config pkgs; };
      "rofi/config-waybar-layout.rasi".text = import ./config/waybar-layout.nix { inherit config pkgs; };
      "rofi/config-waybar-style.rasi".text = import ./config/waybar-style.nix { inherit config pkgs; };
      "rofi/config-zsh-theme.rasi".text = import ./config/zsh-theme.nix { inherit config pkgs; };
    };
  };
}
