{ configRoot, pkgs, ... }:

let
  btopConfigDir = "${configRoot}/config/btop";
in
{
  home = {
    packages = with pkgs; [
      btop
    ];
    file = {
      ".config/btop" = {
        source = "${btopConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
