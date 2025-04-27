{ configRoot, pkgs, ... }:

let
  zshConfigDir = "${configRoot}/config/zsh";
in
{
  programs.zsh = {
    enable = true;
    initExtra = ''
      export K9S_CONFIG_DIR="$HOME/.config/k9s"
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
