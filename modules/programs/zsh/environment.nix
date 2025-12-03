{ ...
}:

{
  shellInit = ''
    # Standard OS variables
    export ZSH_DISABLE_COMPFIX=true
    export EDITOR='nvim'
    export VISUAL='nvim'
    export BROWSER='brave'
    export PODMAN_COLOR=true
    export COLORTERM=truecolor

    # Add homebrew to path (Darwin compatibility)
    export PATH=/opt/homebrew/bin:$PATH
  '';

  loginInit = ''
    # Login shell initialization
    export ZSH_DISABLE_COMPFIX=true
  '';
}
