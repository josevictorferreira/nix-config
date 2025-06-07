{ configRoot, pkgs, ... }:

let
  swayncConfigDir = "${configRoot}/config/swaync";
in
{
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
