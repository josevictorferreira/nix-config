{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;
in
{
  shellInit = lib.mkIf cfg.features.powerLevel10k ''
    # Enable Powerlevel10k instant prompt
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi

    # Source p10k configuration if it exists
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  '';

  # Consider adding p10k as a plugin in plugins.nix instead
}
