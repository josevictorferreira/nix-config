# aliases/notes.nix - Notes management aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Notes
    alias notes='cd ~/Notes && nvim'
    alias nt='cd ~/Notes && nvim'
    alias nsearch='rg ~/Notes'
    # Todo (homelab shared)
    alias gtodo='nvim ~/Homelab/notetaking/01-projects/active/Todo.md'
    # Encrypted plan file (sops)
    alias plan='sops --config=${cfg.workspace.shared}/.sops.yaml ${cfg.workspace.shared}/notetaking/00-inbox/plan.enc.md'
  '';
}
