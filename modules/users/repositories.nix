{
  lib,
  pkgs,
  config,
  inputs,
  system,
  ...
}:

let
  cfg = config.jvf.repositories;
  isDarwin = builtins.match ".*-darwin" system != null;

  mkBody =
    uCfg: userName:
    let
      userConfig = config.users.users.${userName} or { };
      home = if pkgs.stdenv.isDarwin then "/Users/${userName}" else "/home/${userName}";
      group = userConfig.group or (if pkgs.stdenv.isDarwin then "staff" else "users");
    in
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        rel: repo:
        if pkgs.stdenv.isDarwin then
          ''
            if [ ! -d "${home}/${rel}" ]; then
              ${pkgs.coreutils}/bin/mkdir -p "${home}/${rel}"
              GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
                ${pkgs.git}/bin/git clone --depth=1 ${repo} "${home}/${rel}"
            fi
          ''
        else
          inputs.lib.git.cloneRepoText {
            username = userName;
            inherit group repo;
            targetDir = "${home}/${rel}";
          }
      ) uCfg.clonedDirs
    );
in
{
  options.jvf.repositories = {
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

  config = lib.mkMerge (
    [ ]
    ++ lib.optional isDarwin {
      launchd.agents = lib.mkMerge (
        lib.mapAttrsToList (
          userName: uCfg:
          if uCfg.clonedDirs == { } then
            { }
          else
            {
              "jvf-clone-repos-${userName}" = {
                serviceConfig = {
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
                  UserName = userName;
                  GroupName = if pkgs.stdenv.isDarwin then "staff" else "users";
                };
              };
            }
        ) cfg.users
      );
    }
    ++ lib.optional (!isDarwin) {
      system.userActivationScripts = lib.mkMerge (
        lib.mapAttrsToList (
          userName: uCfg:
          if uCfg.clonedDirs == { } then
            { }
          else
            {
              "jvf-clone-repos-${userName}" = ''
                set -euo pipefail
                ${mkBody uCfg userName}
              '';
            }
        ) cfg.users
      );
    }
  );
}
