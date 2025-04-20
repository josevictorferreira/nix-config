{ configRoot, pkgs, ... }:

let
  zshConfigDir = "${configRoot}/config/zsh";
in
{
  programs.zsh = {
    enable = true;
    initExtra = ''
      source $HOME/.config/zsh/init.zsh
    '';
  };

  home = {
    packages = with pkgs; [
      zsh
      fzf
      ripgrep
    ];
    file = {
      ".config/zsh" = {
        source = "${zshConfigDir}";
        recursive = true;
        executable = false;
      };
    };
  };
}
