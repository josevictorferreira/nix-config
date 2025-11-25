{ ...
}:

{
  shellInit = ''
    # Vi mode
    bindkey -v
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down

    # History search keybindings
    bindkey '^R' history-incremental-search-backward
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
    bindkey '^p' history-beginning-search-backward
    bindkey '^n' history-beginning-search-forward

    # Navigation
    bindkey '^[[A' forward-char

    # AI command binding
    bindkey '^G' aicmd

    # FZF history search
    bindkey '^ ' fzf_history_search_prefix_widget

    # Enable cursor blinking
    echo -e '\e[5 q'
  '';
}
