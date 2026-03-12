# oh-my-zsh-darwin.nix - Oh My Zsh configuration for Darwin (manual setup)
# Uses mkAfter to ensure it runs AFTER all other interactiveShellInit content
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf (cfg.setAsDefaultShell) (
    lib.mkAfter ''
      # Manual Oh My Zsh for nix-darwin
      export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh/"
      ZSH_THEME="${cfg.theme}"
      plugins=(${lib.concatStringsSep " " cfg.plugins})

      # Disable oh-my-zsh auto-update (managed by Nix)
      DISABLE_AUTO_UPDATE="true"
      # Disable oh-my-zsh ls colors to prevent it from overriding our eza aliases
      DISABLE_LS_COLORS="true"

      if [ -f $ZSH/oh-my-zsh.sh ]; then
        source $ZSH/oh-my-zsh.sh
      fi
    ''
  );
}
