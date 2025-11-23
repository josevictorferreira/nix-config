{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.jvf.programs.zsh;

in
{
  shellInit = ''
    # Standard OS variables
    export EDITOR='nvim'
    export VISUAL='nvim'
    export BROWSER='brave'
    export PODMAN_COLOR=true
    export COLORTERM=truecolor
    export DIRENV_DISABLE=1

    # Add homebrew to path (Darwin compatibility)
    export PATH=/opt/homebrew/bin:$PATH
  '';

  loginInit = ''
    # Login shell initialization
  '';
}
