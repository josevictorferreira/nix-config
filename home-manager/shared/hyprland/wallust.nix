{ configRoot, pkgs, ... }:

let
  wallustConfigDir = "${configRoot}/dotfiles/wallust";
in
{
  programs.wallust.enable = true;
  home = {
    packages = with pkgs; [
      swww
      wallust
    ];
    file = {
      ".config/wallust" = {
        source = "${wallustConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
