{ configRoot, pkgs, ... }:

let
  zshConfigDir = "${configRoot}/dotfiles/zsh";
in
{
  programs.zsh = {
    enable = true;
    initContent = ''
      export K9S_CONFIG_DIR="$HOME/.config/k9s"
      eval "$(direnv hook zsh)"
      source $HOME/.config/zsh/init.zsh
    '';
  };

  home = {
    packages = with pkgs; [
      zsh
      fzf
      ripgrep
      direnv
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
