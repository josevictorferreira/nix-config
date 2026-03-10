# aliases/base.nix - Base/utility aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Navigation Shortcuts
    alias '..'='cd ..'
    alias '...'='cd ../..'
    alias '....'='cd ../../..'
    alias '~'='cd ~'
    alias -- '-'='cd -'

    # File Operations
    alias cp='cp -i'
    alias mv='mv -i'
    alias rm='rm -i'
    alias mkdir='mkdir -p'

    # Quick Edits
    alias zshconfig='nvim ~/.zshrc'
    alias reload='source ~/.zshrc'
    alias zshenv='nvim ~/.zshenv'

    # System Info
    alias df='df -h'
    alias du='du -h'
    alias psaux='ps aux'

    # Process Management
    alias killport='f() { lsof -ti:$1 | xargs kill -9; }; f'
    alias ports='netstat -tuln'
  '';
}
