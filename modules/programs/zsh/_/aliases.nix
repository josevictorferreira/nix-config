# aliases.nix - Unified aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # ==========================================
    # Base / Utility
    # ==========================================
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

    # ==========================================
    # LS Commands
    # ==========================================
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    alias lt='eza -T --icons --group-directories-first'
    alias tree='eza -T --icons --group-directories-first'

    # ==========================================
    # Directory Navigation
    # ==========================================
    alias ws="cd ${cfg.workspace.root}"
    alias wspc="cd ${cfg.workspace.root}"
    alias hl="cd ${cfg.workspace.root}/homelab"
    alias shared="cd ${cfg.workspace.shared}"
    alias dl='cd ~/Downloads'
    alias doc='cd ~/Documents'
    alias code='cd ~/Workspace'
    alias proj='cd ~/Workspace'
    alias dots='cd ~/.config'
    alias nixcfg='cd ~/.config/nix'
    alias nixc='cd ~/.config/nix'

    # Zoxide Integration
    alias z='__zoxide_z'
    alias zi='__zoxide_zi'

    # ==========================================
    # Development
    # ==========================================
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

    # Helm
    alias h='helm'
    alias hi='helm install'
    alias hu='helm upgrade'
    alias hd='helm delete'
    alias hls='helm list'
    alias hs='helm status'
    alias hg='helm get'

    # Flux
    alias fgs='flux get sources all'
    alias fgk='flux get kustomizations'
    alias fgh='flux get helmreleases'
    alias fr='flux reconcile'
    alias frs='flux reconcile source'
    alias frk='flux reconcile kustomization'
    alias frh='flux reconcile helmrelease'

    # K9s
    alias k9s='k9s'

    # ==========================================
    # Notes Management
    # ==========================================
    alias notes='cd ~/Notes && nvim'
    alias nt='cd ~/Notes && nvim'
    alias nsearch='rg ~/Notes'
    # Todo (homelab shared)
    alias gtodo='nvim ~/Homelab/notetaking/01-projects/active/Todo.md'
    # Encrypted plan file (sops)
    alias plan="sops --config='${cfg.workspace.shared}/.sops.yaml' '${cfg.workspace.shared}/notetaking/00-inbox/plan.enc.md'"

    # ==========================================
    # Work & Homelab
    # ==========================================
    alias work="cd ${cfg.workspace.root}"
    alias homelab="cd ${cfg.workspace.shared}"
    alias infra="cd ${cfg.workspace.shared}/infrastructure 2>/dev/null || cd ~/Homelab/infrastructure"
    alias k8s_homelab="cd ${cfg.workspace.shared}/kubernetes 2>/dev/null || cd ~/Homelab/kubernetes"
    alias monitoring="cd ${cfg.workspace.shared}/monitoring 2>/dev/null || cd ~/Homelab/monitoring"

    # ==========================================
    # Specific Projects
    # ==========================================
    # Agrosmart
    alias agro="cd ${cfg.workspace.root}/agrosmart"
    alias nexus="cd ${cfg.workspace.root}/agrosmart/nexus"
    alias nex="cd ${cfg.workspace.root}/agrosmart/nexus/nexus-backend"
    alias boost="cd ${cfg.workspace.root}/agrosmart/booster/boosteragro"
    alias booster="cd ${cfg.workspace.root}/agrosmart/booster/boosteragro"
    alias as="cd ${cfg.workspace.root}/agrosmart 2>/dev/null || cd ~/Workspace/agrosmart"
    alias val="cd ${cfg.workspace.root}/valoris 2>/dev/null || cd ~/Workspace/valoris"
    alias valb="cd ${cfg.workspace.root}/valoris/backend 2>/dev/null || cd ~/Workspace/valoris/backend"
    alias valf="cd ${cfg.workspace.root}/valoris/valoris-frontend 2>/dev/null || cd ~/Workspace/valoris/frontend"
    alias exer="cd ${cfg.workspace.root}/exercism"
    alias readm="cd ${cfg.workspace.root}/readmore-project"
    alias ebook="cd ${cfg.workspace.root}/ebookit"
    alias ebookit="cd ${cfg.workspace.root}/ebookit/ebookit-extension"
    alias rinha="cd ${cfg.workspace.root}/rinha-backend"
  '';
}
