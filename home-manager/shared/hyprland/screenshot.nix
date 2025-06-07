{ configRoot, pkgs, ... }:

let
  swappyConfigDir = "${configRoot}/config/swappy";
in
{
  home = {
    packages = with pkgs; [
      grim
      grimblast
      hyprshot
      swappy
    ];
    file = {
      ".config/swappy" = {
        source = "${swappyConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
