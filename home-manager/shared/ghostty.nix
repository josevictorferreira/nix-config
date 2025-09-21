{ pkgs, configRoot, isDarwin, ... }:

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
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ] ++ lib.optional (!isDarwin) ghostty;
  };
}
