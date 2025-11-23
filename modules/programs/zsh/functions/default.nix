{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;

  development = import ./development.nix { inherit lib pkgs config; };
  kubernetes = import ./kubernetes.nix { inherit lib pkgs config; };
  navigation = import ./navigation.nix { inherit lib pkgs config; };
  gitAi = import ./git-ai.nix { inherit lib pkgs config; };
in
{
  # Aggregate all packages
  packages =
    development.packages
    ++ kubernetes.packages
    ++ navigation.packages
    ++ (lib.optionals cfg.features.aiCommit gitAi.commitPackages)
    ++ (lib.optionals cfg.features.aiCommand gitAi.commandPackages);

  # Aggregate shell init scripts
  shellInit = lib.concatStringsSep "\n\n" [
    "# Development Functions"
    development.functions

    "# Kubernetes Functions"
    kubernetes.functions

    "# Navigation Functions"
    navigation.functions

    "# Git AI Functions"
    (lib.optionalString cfg.features.aiCommit gitAi.commitShellInit)
    (lib.optionalString cfg.features.aiCommand gitAi.commandShellInit)
  ];
}
