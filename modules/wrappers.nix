# Aspect: wrappers
# Wrapper scripts + PATH/env management for per-user programs.
# NixOS: per-user activation scripts with supportsDryActivation.
# Darwin: postActivation script for all users.
# Config files/dirs managed via jvf.home.
_:
let
  # Shared option definition — identical for both platforms
  mkWrappersOption =
    { lib, ... }:
    {
      options.jvf.wrappers = {
        users = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (_: {
              options.programs = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule (_: {
                    options = {
                      packages = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = "Packages to include in wrapper environment.";
                      };

                      command = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Command to execute in wrapper. If null or empty, no wrapper script is created.";
                      };

                      env = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = { };
                        description = "Environment variables for wrapper.";
                      };
                    };
                  })
                );
                default = { };
                description = "Programs to wrap and install.";
              };
            })
          );
          default = { };
        };
      };
    };

  # Shared implementation logic, parameterized by platform
  mkWrappersConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.wrappers;

      mkProgramWrapper =
        { userName
        , programName
        , packages
        , command ? null
        , env ? { }
        }:
        let
          wrapperScript =
            if command == null || command == "" then
              null
            else
              let
                envVars = lib.mapAttrsToList (name: value: "export ${name}='${value}'") env;
                envStr = lib.concatStringsSep "
"
                  envVars;
              in
              pkgs.writeShellScriptBin programName ''
                ${envStr}
                exec ${command} "$@"
              '';

          wrapperEnv =
            if wrapperScript == null then
              null
            else
              pkgs.symlinkJoin {
                name = "${programName}-env";
                paths = [ wrapperScript ] ++ packages;
              };
        in
        {
          inherit wrapperEnv;
        };

      mkUserActivation =
        userName: uCfg:
        let
          home = if config.users.users.${userName}.home != null then config.users.users.${userName}.home else if isDarwin then "/Users/${userName}" else "/home/${userName}";
        in
        "(
          "
        + ''
          set -e
        ''
        + lib.concatStringsSep "
"
          (
            lib.mapAttrsToList
              (
                programName: programCfg:
                let
                  wrapper = mkProgramWrapper {
                    inherit userName programName;
                    inherit (programCfg)
                      packages
                      command
                      env
                      ;
                  };

                  installWrapper =
                    if wrapper.wrapperEnv == null then
                      ""
                    else
                      ''
                        echo "Installing wrapper for ${programName}..."
                        mkdir -p ${home}/.local/bin
                        ln -sf ${wrapper.wrapperEnv}/bin/${programName} ${home}/.local/bin/
                      '';
                in
                ''
                  ${installWrapper}
                ''
              )
              (uCfg.programs or { })
          )
        + ''
            true
          )
        '';

      # Packages for users whose programs have no wrapper command (command == null)
      userPackagesConfig = {
        users.users = lib.mkMerge (
          lib.mapAttrsToList
            (
              userName: uCfg:
                let
                  userPackages = lib.flatten (
                    lib.mapAttrsToList
                      (
                        _: programCfg:
                          if programCfg.command == null || programCfg.command == "" then programCfg.packages or [ ] else [ ]
                      )
                      (uCfg.programs or { })
                  );
                in
                if userPackages == [ ] then
                  { }
                else
                  {
                    "${userName}" = {
                      packages = userPackages;
                    };
                  }
            )
            cfg.users
        );
      };
    in
    {
      imports = [ mkWrappersOption ];

      config = lib.mkMerge (
        [
          userPackagesConfig
        ]
        ++ lib.optional isDarwin {
          system.activationScripts.postActivation.text = lib.concatStringsSep "
"
            (
              lib.flatten (
                lib.mapAttrsToList
                  (
                    userName: uCfg: if (uCfg.programs or { }) == { } then [ ] else [ (mkUserActivation userName uCfg) ]
                  )
                  cfg.users
              )
            );
        }
        ++ lib.optional (!isDarwin) {
          system.activationScripts = lib.mkMerge (
            lib.mapAttrsToList
              (
                userName: uCfg:
                  if (uCfg.programs or { }) == { } then
                    { }
                  else
                    {
                      "jvf-wrappers-${userName}" = {
                        supportsDryActivation = true;
                        text = mkUserActivation userName uCfg;
                      };
                    }
              )
              cfg.users
          );
        }
      );
    };
in
{
  flake.modules.nixos.wrappers = mkWrappersConfig { isDarwin = false; };
  flake.modules.darwin.wrappers = mkWrappersConfig { isDarwin = true; };
}
