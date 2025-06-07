{ configRoot, pkgs, ... }:

let
  kvantumConfigDir = "${configRoot}/config/Kvantum";
in
{
  home = {
    packages = with pkgs; [
      kvantum
    ];
    file = {
      ".config/Kvantum" = {
        source = "${kvantumConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
