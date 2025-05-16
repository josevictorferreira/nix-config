{ configRoot, pkgs, ... }:

let
  rofiConfigDir = "${configRoot}/config/rofi";
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
