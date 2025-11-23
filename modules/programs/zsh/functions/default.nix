{
  lib,
  pkgs,
  config,
  ...
}:

let
  development = import ./development.nix { inherit lib pkgs config; };
  kubernetes = import ./kubernetes.nix { inherit lib pkgs config; };
  navigation = import ./navigation.nix { inherit lib pkgs config; };
  gitAi = import ./git-ai.nix { inherit lib pkgs config; };
in
{
  # Aggregate all packages
  packages = development.packages ++ kubernetes.packages ++ navigation.packages ++ gitAi.packages;

  # Aggregate shell init scripts
  shellInit = lib.concatStringsSep "\n\n" [
    "# Development Functions"
    development.shellInit

    "# Kubernetes Functions"
    kubernetes.shellInit

    "# Navigation Functions"
    navigation.shellInit

    "# Git AI Functions"
    gitAi.shellInit
  ];
}
