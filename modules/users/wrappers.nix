{
  lib,
  pkgs,
  config,
  jvfLib,
  isDarwin,
  ...
}:

let
  cfg = config.jvf.wrappers;

  getFileExtension =
    fileName:
    let
      parts = builtins.split "\\." fileName;
      extension =
        if builtins.length parts > 1 then (builtins.elemAt parts (builtins.length parts - 1)) else "";
    in
    extension;

  processConfigs =
    { configs, programName }:
    if configs == { } then
      { }
    else
      lib.mapAttrs (
        fileName: fileValue:
        if builtins.isPath fileValue then
          {
            name = fileName;
            path = fileValue;
          }
        else if builtins.isAttrs fileValue then
          let
            ext = getFileExtension fileName;
            content = jvfLib.generators.toFileFormatStr ext fileValue;
          in
          {
            name = fileName;
            path = pkgs.writeText "${programName}-${fileName}" content;
          }
        else
          throw "Config value for ${fileName} must be either a path or an attrset"
      ) configs;

  mkProgramWrapper =
    {
      userName,
      programName,
      packages,
      command,
      env ? { },
      configs ? { },
      useDerivationConfig ? false,
    }:
    let
      userConfig = config.users.users.${userName} or { };
      home = userConfig.home or (if isDarwin then "/Users/${userName}" else "/home/${userName}");

      processedConfigs = processConfigs { inherit configs programName; };

      configDir =
        if processedConfigs == { } then
          null
        else
          pkgs.linkFarm "${programName}-config" (lib.mapAttrsToList (_: v: v) processedConfigs);

      wrapperScript =
        let
          envVars = lib.mapAttrsToList (name: value: "export ${name}='${value}'") env;
          envStr = lib.concatStringsSep "\n" envVars;
        in
        pkgs.writeShellScriptBin programName ''
          ${envStr}
          exec ${command} "$@"
        '';

      wrapperEnv = pkgs.symlinkJoin {
        name = "${programName}-env";
        paths = [ wrapperScript ] ++ packages;
      };
    in
    {
      inherit wrapperEnv configDir;
      configTargetDir = if useDerivationConfig then null else "${home}/.config/${programName}";
    };

  mkUserActivation =
    userName: uCfg:
    let
      userConfig = config.users.users.${userName} or { };
      home = userConfig.home or (if isDarwin then "/Users/${userName}" else "/home/${userName}");
    in
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        programName: programCfg:
        let
          wrapper = mkProgramWrapper (
            {
              inherit userName programName;
            }
            // programCfg
          );

          installWrapper = ''
            echo "Installing wrapper for ${programName}..."
            mkdir -p ${home}/.local/bin
            ln -sf ${wrapper.wrapperEnv}/bin/${programName} ${home}/.local/bin/
            chown ${userName}:users ${home}/.local/bin/${programName}
          '';

          setupConfig =
            if wrapper.configDir == null || (programCfg.useDerivationConfig or false) then
              ""
            else
              let
                targetDir = "${home}/.config/${programName}";
              in
              ''
                echo "Setting up config for ${programName}..."
                if [ -e "${targetDir}" ] && [ ! -L "${targetDir}" ]; then
                  echo "Backing up existing ${programName} config..."
                  mv "${targetDir}" "${targetDir}.backup.$(date +%s)"
                fi
                rm -f "${targetDir}"
                ln -sf ${wrapper.configDir} "${targetDir}"
                chown -R ${userName}:users "${targetDir}"
              '';
        in
        ''
          ${installWrapper}
          ${setupConfig}
        ''
      ) (uCfg.programs or { })
    );

  defaultOptions = {
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options.programs = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule (
                  { ... }:
                  {
                    options = {
                      name = lib.mkOption {
                        type = lib.types.str;
                        description = "Program name (used for wrapper binary).";
                      };

                      packages = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = "Packages to include in wrapper environment.";
                      };

                      command = lib.mkOption {
                        type = lib.types.str;
                        description = "Command to execute in wrapper.";
                      };

                      env = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = { };
                        description = "Environment variables for wrapper.";
                      };

                      configs = lib.mkOption {
                        type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.attrs);
                        default = { };
                        description = ''
                          Configuration files. Keys are filenames, values are either:
                          - Path: copied as-is
                          - Attrset: converted based on file extension (.json, .yaml, .toml, .ini)
                        '';
                      };

                      useDerivationConfig = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Keep configs in derivation instead of symlinking to ~/.config/{name}/";
                      };
                    };
                  }
                )
              );
              default = { };
              description = "Programs to wrap and install.";
            };
          }
        )
      );
      default = { };
    };
  };

  darwinModule = {
    options.jvf.wrappers = defaultOptions;

    config = {
      launchd.daemons = lib.mkMerge (
        lib.mapAttrsToList (
          userName: uCfg:
          if (uCfg.programs or { }) == { } then
            { }
          else
            {
              "jvf-wrappers-${userName}" = {
                config = {
                  ProgramArguments = [
                    "${pkgs.bash}/bin/bash"
                    "-c"
                    (mkUserActivation userName uCfg)
                  ];
                  RunAtLoad = true;
                  StandardOutPath = "/tmp/jvf-wrappers-${userName}.log";
                  StandardErrorPath = "/tmp/jvf-wrappers-${userName}.err";
                };
              };
            }
        ) cfg.users
      );
    };
  };

  defaultModule = {
    options.jvf.wrappers = defaultOptions;

    config = {
      system.activationScripts = lib.mkMerge (
        lib.mapAttrsToList (
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
        ) cfg.users
      );
    };
  };
in
if isDarwin then darwinModule else defaultModule
