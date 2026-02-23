# aliases/work.nix - Work-specific aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Work shortcuts
    "work" = "cd ${cfg.workspace.root}";
    "homelab" = "cd ${cfg.workspace.shared}";
    "infra" = "cd ${cfg.workspace.shared}/infrastructure 2>/dev/null || cd ~/Homelab/infrastructure";
    "k8s" = "cd ${cfg.workspace.shared}/kubernetes 2>/dev/null || cd ~/Homelab/kubernetes";
    "monitoring" = "cd ${cfg.workspace.shared}/monitoring 2>/dev/null || cd ~/Homelab/monitoring";
  };
}
