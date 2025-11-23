{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;

  # Build secret exports if enabled
  secretExports = ''
    export OPENROUTER_API_KEY_TERMINAL=$(cat /run/secrets/openrouter_terminal)
    export OPENROUTER_API_KEY_COMMIT=$(cat /run/secrets/openrouter_commit)
    export OPENROUTER_API_KEY_AUTOCOMPLETE=$(cat /run/secrets/openrouter_autocomplete)
    export OPENROUTER_API_KEY_CODE_AGENT=$(cat /run/secrets/openrouter_code_agent)
    export CONTEXT7_API_KEY=$(cat /run/secrets/context7_api_key)
    export GITHUB_TOKEN=$(cat /run/secrets/github_token)
  '';

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

    ${secretExports}
  '';

  loginInit = ''
    # Login shell initialization
  '';
}
