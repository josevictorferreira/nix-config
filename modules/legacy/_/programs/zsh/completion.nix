{ ...
}:

{
  shellInit = ''
    # Completion settings
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

    # FZF tab completion
    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:*' popup-min-size 80 12
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1a --color=always $realpath'
  '';
}
