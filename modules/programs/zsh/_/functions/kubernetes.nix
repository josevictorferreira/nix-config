# functions/kubernetes.nix - Kubernetes helper functions
{ config, lib, pkgs, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Switch kubernetes contexts using fzf
    function ksc() {
      local contexts=$(${pkgs.kubectl}/bin/kubectl config get-contexts -o name)
      local selected_context=$(echo "''${contexts}" | ${pkgs.fzf}/bin/fzf)

      if [ -n "$selected_context" ]; then
        ${pkgs.kubectl}/bin/kubectl config use-context "$selected_context"
      else
        echo "No context selected."
      fi
    }
  '';
}
