# shell-init/completion.nix - ZSH completion configuration
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh = lib.mkIf cfg.setAsDefaultShell {
    enableCompletion = true;
    interactiveShellInit = ''
      # Completion System
      autoload -Uz compinit
      if [[ -n "$ZSH_CUSTOM" ]]; then
        compinit -d "$ZSH_CUSTOM/.zcompdump"
      else
        compinit
      fi

      # Completion Options
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zsh/cache
    '';
  };
}
