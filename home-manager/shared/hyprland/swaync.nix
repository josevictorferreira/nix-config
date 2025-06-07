{ configRoot, pkgs, ... }:

let
  swayncConfigDir = "${configRoot}/config/swaync";
in
{
  programs.swaync.enable = true;
  home = {
    packages = with pkgs; [
      swaynotificationcenter
    ];
    file = {
      ".config/swaync" = {
        source = "${swayncConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
