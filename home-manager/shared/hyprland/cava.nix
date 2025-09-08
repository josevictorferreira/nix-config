{ configRoot, pkgs, ... }:

let
  cavaConfigDir = "${configRoot}/dotfiles/cava";
in
{
  home = {
    packages = with pkgs; [
      cava
    ];
    file = {
      ".config/cava" = {
        source = "${cavaConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
