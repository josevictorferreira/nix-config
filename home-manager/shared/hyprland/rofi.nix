{ configRoot, pkgs, ... }:

let
  rofiConfigDir = "${configRoot}/dotfiles/rofi";
in
{
  home = {
    packages = with pkgs; [
      rofi-wayland
    ];
    file = {
      ".config/rofi" = {
        source = "${rofiConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
