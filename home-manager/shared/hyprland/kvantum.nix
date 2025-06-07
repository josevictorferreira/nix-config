{ configRoot, ... }:

let
  kvantumConfigDir = "${configRoot}/config/Kvantum";
in
{
  home = {
    file = {
      ".config/Kvantum" = {
        source = "${kvantumConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
