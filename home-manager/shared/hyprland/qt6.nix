{ configRoot, pkgs, ... }:

let
  qt6ctConfigDir = "${configRoot}/dotfiles/qt6ct";
in
{
  home = {
    packages = with pkgs; [
      qt6ct
      qt6.qtwayland
      qt6Packages.qtstyleplugin-kvantum #kvantum
    ];
    file = {
      ".config/qt6ct" = {
        source = "${qt6ctConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
