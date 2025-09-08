{ configRoot, pkgs, ... }:

let
  swayncConfigDir = "${configRoot}/dotfiles/swaync";
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
