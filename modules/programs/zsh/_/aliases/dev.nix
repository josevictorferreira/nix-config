# aliases/dev.nix - Development aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Git
    "g" = "git";
    "ga" = "git add";
    "gaa" = "git add --all";
    "gc" = "git commit -v";
    "gcmsg" = "git commit -m";
    "gco" = "git checkout";
    "gcb" = "git checkout -b";
    "gb" = "git branch";
    "gba" = "git branch -a";
    "gd" = "git diff";
    "gf" = "git fetch";
    "gl" = "git pull";
    "gp" = "git push";
    "gst" = "git status";
    "glog" = "git log --oneline --decorate --graph";
    "gloga" = "git log --oneline --decorate --graph --all";

    # Docker
    "d" = "docker";
    "dc" = "docker compose";
    "dps" = "docker ps";
    "dpsa" = "docker ps -a";
    "di" = "docker images";
    "dex" = "docker exec -it";
    "dlogs" = "docker logs";
    "drun" = "docker run --rm -it";

    # Nix
    "nx" = "nix";
    "nxf" = "nix flake";
    "nxu" = "nix flake update";
    "nxr" = "sudo nixos-rebuild switch";
    "nxh" = "home-manager switch";
    "nxs" = "nix search nixpkgs";
    "nxe" = "nix-shell -p";
    "nxp" = "nix-shell -p";

    # Kubernetes
    "k" = "kubectl";
    "kg" = "kubectl get";
    "kd" = "kubectl describe";
    "kdel" = "kubectl delete";
    "ka" = "kubectl apply -f";
    "kaf" = "kubectl apply -f";
    "kex" = "kubectl exec -it";
    "klogs" = "kubectl logs";
    "kp" = "kubectl get pods";
    "ks" = "kubectl get svc";
    "kns" = "kubectl config set-context --current --namespace";
    "kctx" = "kubectl config use-context";
    "kconf" = "kubectl config view";
  };
}
