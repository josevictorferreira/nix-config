{ configRoot, pkgs, ... }:

let
  qt5ctConfigDir = "${configRoot}/config/qt5ct";
in
{
  home = {
    packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum #kvantum
      libsForQt5.qt5ct
    ];
    file = {
      ".config/qt5ct" = {
        source = "${qt5ctConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
