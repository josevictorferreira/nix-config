# aliases/k8s.nix - Kubernetes-specific aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Helm
    "h" = "helm";
    "hi" = "helm install";
    "hu" = "helm upgrade";
    "hd" = "helm delete";
    "hl" = "helm list";
    "hs" = "helm status";
    "hg" = "helm get";

    # Flux
    "flux" = "flux";
    "fgs" = "flux get sources all";
    "fgk" = "flux get kustomizations";
    "fgh" = "flux get helmreleases";
    "fr" = "flux reconcile";
    "frs" = "flux reconcile source";
    "frk" = "flux reconcile kustomization";
    "frh" = "flux reconcile helmrelease";

    # K9s
    "k9s" = "k9s";
  };
}
