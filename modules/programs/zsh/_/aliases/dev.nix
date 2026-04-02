# aliases/dev.nix - Development aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Editor
    alias v='nvim'

    # Make
    alias m='make'

    # Git
    alias g='git'
    alias ga='git add'
    alias gaa='git add --all'
    alias gc='git commit -v'
    alias gcmsg='git commit -m'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gb='git branch'
    alias gba='git branch -a'
    alias gd='git diff'
    alias gf='git fetch'
    alias gl='git pull'
    alias gp='git push'
    alias gst='git status'
    alias glog='git log --oneline --decorate --graph'
    alias gloga='git log --oneline --decorate --graph --all'

    # Docker
    alias d='docker'
    alias dc='docker compose'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlogs='docker logs'
    alias drun='docker run --rm -it'

    # Ruby
    alias be='bundle exec '
    alias ber='bundle exec rspec'

    # Nix
    alias nx='nix'
    alias nxf='nix flake'
    alias nxu='nix flake update'
    alias nxs='nix search nixpkgs'
    alias nxe='nix-shell -p'
    alias nxp='nix-shell -p'
    alias nd='nix develop -c zsh'

    # Kubernetes
    alias k='kubectl'
    alias kg='kubectl get'
    alias kd='kubectl describe'
    alias kdel='kubectl delete'
    alias ka='kubectl apply -f'
    alias kaf='kubectl apply -f'
    alias kex='kubectl exec -it'
    alias klogs='kubectl logs'
    alias kp='kubectl get pods'
    alias ks='kubectl get svc'
    alias kns='kubectl config set-context --current --namespace'
    alias kctx='kubectl config use-context'
    alias kconf='kubectl config view'
  '';
}
