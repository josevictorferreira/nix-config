{ configRoot, pkgs, ... }:

let
  waybarConfigDir = "${configRoot}/config/waybar";
in
{
  programs.waybar.enable = true;
  home = {
    packages = with pkgs; [
      waybar
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
