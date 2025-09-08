{ configRoot, pkgs, ... }:

let
  wlogoutConfigDir = "${configRoot}/dotfiles/wlogout";
in
{
  home = {
    packages = with pkgs; [
      wlogout
    ];
    file = {
      ".config/wlogout" = {
        source = "${wlogoutConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
