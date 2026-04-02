# aliases/work.nix - Work-specific aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Work shortcuts
    alias work='cd ${cfg.workspace.root}'
    alias homelab='cd ${cfg.workspace.shared}'
    alias infra='cd ${cfg.workspace.shared}/infrastructure 2>/dev/null || cd ~/Homelab/infrastructure'
    alias k8s='cd ${cfg.workspace.shared}/kubernetes 2>/dev/null || cd ~/Homelab/kubernetes'
    alias monitoring='cd ${cfg.workspace.shared}/monitoring 2>/dev/null || cd ~/Homelab/monitoring'

    # Homelab Projects
    alias valb='cd ${cfg.workspace.shared}/backend 2>/dev/null || cd ~/Homelab/backend'
    alias valf='cd ${cfg.workspace.shared}/frontend 2>/dev/null || cd ~/Homelab/frontend'
    alias occ='v ${cfg.workspace.shared}/openclaw/openclaw.json 2>/dev/null || v ~/Homelab/openclaw/openclaw.json'
  '';
}
