{ pkgs, configRoot, ... }:

let
  ghosttyConfigDir = "${configRoot}/config/ghostty";
in
{
  home = {
    file = {
      ".config/ghostty" = {
        source = "${ghosttyConfigDir}";
        recursive = true;
        executable = false;
      };
    };
    packages = with pkgs; [
      ghostty
      nerd-fonts.jetbrains-mono
    ];
  };
  fonts.fontconfig.enable = true;
}
