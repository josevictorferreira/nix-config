{
  lib,
  config,
  ...
}:

let
  cfg = config.jvf.programs.zsh;
in
{
  shellInit = ''
    # Vi mode
    ${lib.optionalString cfg.features.viMode "bindkey -v"}

    # History search keybindings
    bindkey '^R' history-incremental-search-backward
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
    bindkey '^p' history-beginning-search-backward
    bindkey '^n' history-beginning-search-forward

    ${lib.optionalString cfg.features.viMode ''
      # Vi mode specific bindings
      bindkey -M vicmd 'k' history-substring-search-up
      bindkey -M vicmd 'j' history-substring-search-down
    ''}

    # Navigation
    bindkey '^[[A' forward-char

    # AI command binding
    ${lib.optionalString cfg.features.aiCommand "bindkey '^G' aicmd"}

    # FZF history search
    ${lib.optionalString cfg.features.advancedHistory "bindkey '^ ' fzf_history_search_prefix_widget"}

    # Enable cursor blinking
    echo -e '\e[5 q'
  '';
}
