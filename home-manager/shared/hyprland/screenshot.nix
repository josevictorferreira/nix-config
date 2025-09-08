{ configRoot, pkgs, ... }:

let
  swappyConfigDir = "${configRoot}/dotfiles/swappy";
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
