{ configRoot, pkgs, ... }:

let
  waybarConfigDir = "${configRoot}/dotfiles/waybar";
in
{
  programs.waybar.enable = true;
  home = {
    packages = with pkgs; [
      swww
      wallust
    ];
    file = {
      ".config/waybar" = {
        source = "${waybarConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
