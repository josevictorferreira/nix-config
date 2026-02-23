# shell-init/keybindings.nix - ZSH keybindings configuration
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Keybindings
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
    bindkey '^[[H' beginning-of-line
    bindkey '^[[F' end-of-line
    bindkey '^[[3~' delete-char

    # FZF Tab
    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -la $realpath'
  '';
}
