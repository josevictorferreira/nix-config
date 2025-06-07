{ configRoot, pkgs, ... }:

let
  wlogoutConfigDir = "${configRoot}/config/wlogout";
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
