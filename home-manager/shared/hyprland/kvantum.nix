{ configRoot, ... }:

let
  kvantumConfigDir = "${configRoot}/dotfiles/Kvantum";
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
