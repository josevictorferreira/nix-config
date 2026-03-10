# aliases/k8s.nix - Kubernetes-specific aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
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
  '';
}
