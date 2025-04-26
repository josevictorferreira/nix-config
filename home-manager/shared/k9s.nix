{ pkgs, configRoot, ... }:

let
  k9sConfigDir = "${configRoot}/config/k9s";
in
{
  home = {
    file = {
      ".config/k9s" = {
        source = "${k9sConfigDir}";
        recursive = true;
        executable = false;
      };
    };
    packages = with pkgs; [
      k9s
    ];
  };
}
