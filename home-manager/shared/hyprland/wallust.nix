{ configRoot, pkgs, ... }:

let
  wallustConfigDir = "${configRoot}/config/wallust";
in
{
  programs.wallust.enable = true;
  home = {
    packages = with pkgs; [
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
