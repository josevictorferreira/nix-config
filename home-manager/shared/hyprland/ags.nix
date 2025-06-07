{ configRoot, pkgs, ... }:

let
  agsConfigDir = "${configRoot}/config/ags";
in
{
  home = {
    packages = with pkgs; [
      ags
    ];
    file = {
      ".config/ags" = {
        source = "${agsConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
