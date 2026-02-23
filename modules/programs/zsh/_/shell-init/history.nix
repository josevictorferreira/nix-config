# shell-init/history.nix - ZSH history configuration
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellInit = lib.mkIf cfg.setAsDefaultShell ''
    # History Configuration
    HISTFILE="$HOME/.zsh_history"
    HISTSIZE=1000000
    SAVEHIST=1000000
  '';

  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # History Options
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_FIND_NO_DUPS
    setopt HIST_SAVE_NO_DUPS
    setopt HIST_REDUCE_BLANKS
    setopt HIST_VERIFY
    setopt SHARE_HISTORY
    setopt EXTENDED_HISTORY
  '';
}
