{
  lib,
  pkgs,
  config,
  jvfLib,
  isDarwin,
  ...
}:

let
  cfg = config.jvf.users.repositories;

  defaultOptions = {
    enable = lib.mkEnableOption "per-user repo cloning on switch (once per target)";

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options.clonedDirs = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              example = {
                ".config/easyeffects" = "git@github.com:you/.easyeffects.git";
              };
              description = "Relative path -> SSH repo to clone once into user's home.";
            };
          }
        )
      );
      default = { };
    };
  };

  darwinModule = {
    options.jvf.users.repositories = defaultOptions;
  };

  defaultModule = {
    options.jvf.users.repositories = defaultOptions;

    config = lib.mkIf cfg.enable {
      system.activationScripts = lib.mkMerge (
        lib.mapAttrsToList (
          userName: uCfg:
          let
            home = config.users.users.${userName}.home or "/home/${userName}";
            group = config.users.users.${userName}.group or "users";
            body = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                rel: repo:
                jvfLib.git.cloneOnceText {
                  inherit pkgs repo;
                  user = userName;
                  inherit group home rel;
                }
              ) uCfg.clonedDirs
            );
          in
          if uCfg.clonedDirs == { } then
            { }
          else
            {
              "jvf-clone-repos-${userName}" = {
                supportsDryActivation = true;
                text = ''
                  set -euo pipefail
                  ${body}
                '';
              };
            }
        ) cfg.users
      );
    };
  };
in
if isDarwin then darwinModule else defaultModule
