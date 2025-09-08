{ pkgs, configRoot, ... }:

let
  ghosttyConfigDir = "${configRoot}/dotfiles/ghostty";
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
      nerd-fonts.fira-code
    ];
  };
}
