{
  lib,
  pkgs,
  config,
  jvfLib,
  isDarwin,
  ...
}:

let
  cfg = config.jvf.repositories;

  mkBody =
    uCfg: userName:
    let
      userConfig = config.users.users.${userName} or { };
      home = userConfig.home or (if isDarwin then "/Users/${userName}" else "/home/${userName}");
      group = userConfig.group or (if isDarwin then "staff" else "users");
    in
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        rel: repo:
        jvfLib.git.cloneRepoText {
          username = userName;
          inherit group repo;
          targetDir = "${home}/${rel}";
        }
      ) uCfg.clonedDirs
    );

  defaultOptions = {
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
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
    options.jvf.repositories = defaultOptions;

    config = {
      launchd.daemons = lib.mkMerge (
        lib.mapAttrsToList (
          userName: uCfg:
          if uCfg.clonedDirs == { } then
            { }
          else
            {
              "jvf-clone-repos-${userName}" = {
                config = {
                  ProgramArguments = [
                    "${pkgs.bash}/bin/bash"
                    "-c"
                    ''
                      set -euo pipefail
                      ${mkBody uCfg userName}
                    ''
                  ];
                  RunAtLoad = true;
                  StandardOutPath = "/tmp/jvf-clone-repos-${userName}.log";
                  StandardErrorPath = "/tmp/jvf-clone-repos-${userName}.err";
                };
              };
            }
        ) cfg.users
      );
    };
  };

  defaultModule = {
    options.jvf.repositories = defaultOptions;

    config = {
      system.activationScripts = lib.mkMerge (
        lib.mapAttrsToList (
          userName: uCfg:
          if uCfg.clonedDirs == { } then
            { }
          else
            {
              "jvf-clone-repos-${userName}" = {
                supportsDryActivation = true;
                text = ''
                  set -euo pipefail
                  ${mkBody uCfg userName}
                '';
              };
            }
        ) cfg.users
      );
    };
  };
in
if isDarwin then darwinModule else defaultModule
