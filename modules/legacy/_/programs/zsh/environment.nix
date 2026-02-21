{ ...
}:

{
  shellInit = ''
    # XDG Compliance
    export ZDOTDIR=$HOME/.config/zsh
    mkdir -p $ZDOTDIR
    mkdir -p $HOME/.cache/zsh

    # Standard OS variables
    export ZSH_DISABLE_COMPFIX=true
    export EDITOR='nvim'
    export VISUAL='nvim'
    export BROWSER='brave'
    export PODMAN_COLOR=true
    export COLORTERM=truecolor

    # Fix TERM for kitty (may inherit wrong TERM from parent tmux)
    [[ -n "$KITTY_WINDOW_ID" && "$TERM" != "xterm-kitty" ]] && export TERM=xterm-kitty

    # Add local bin and homebrew to path
    export PATH=$HOME/.local/bin:/opt/homebrew/bin:$PATH
  '';

  loginInit = ''
    # Login shell initialization
    export ZSH_DISABLE_COMPFIX=true
  '';
}
