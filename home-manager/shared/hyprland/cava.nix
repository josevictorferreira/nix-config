{ configRoot, pkgs, ... }:

let
  cavaConfigDir = "${configRoot}/config/cava";
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
