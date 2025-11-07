{ lib
, pkgs
, config
, jvfLib
, isDarwin
, ...
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
      lib.mapAttrs
        (
          fileName: fileValue:
          if builtins.isPath fileValue then
          # Check if the path is a directory
            let
              isDir = builtins.tryEval (
                if builtins.pathExists fileValue then
                  let
                    dirContents = builtins.readDir fileValue;
                  in
                  # If we can read the directory and it's not empty, it's likely a directory
                  dirContents != { }
                else
                  false
              );
            in
            if isDir.success && isDir.value then
            # It's a directory, use linkFarm to copy the entire directory structure
              {
                name = fileName;
                path = pkgs.linkFarm "${programName}-${fileName}-dir" (
                  lib.mapAttrsToList
                    (
                      entryName: entryType:
                        {
                          name = entryName;
                          path = "${fileValue}/${entryName}";
                        }
                    )
                    (builtins.readDir fileValue)
                );
              }
            else
            # It's a file, use as-is
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
        )
        configs;

  mkProgramWrapper =
    { userName
    , programName
    , packages
    , command ? null
    , env ? { }
    , configs ? { }
    , useDerivationConfig ? false
    ,
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
        if command == null || command == "" then
          null
        else
          let
            envVars = lib.mapAttrsToList (name: value: "export ${name}='${value}'") env;
            envStr = lib.concatStringsSep "\n" envVars;
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
      lib.mapAttrsToList
        (
          programName: programCfg:
          let
            wrapper = mkProgramWrapper {
              inherit userName programName;
              inherit (programCfg) packages command env configs useDerivationConfig;
            };

            installWrapper =
              if wrapper.wrapperEnv == null then
              # No wrapper script, packages are already available in system/environment
                ""
              else
                ''
                  echo "Installing wrapper for ${programName}..."
                  mkdir -p ${home}/.local/bin
                  ln -sf ${wrapper.wrapperEnv}/bin/${programName} ${home}/.local/bin/
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
                '';
          in
          ''
            ${installWrapper}
            ${setupConfig}
          ''
        )
        (uCfg.programs or { })
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
        lib.mapAttrsToList
          (
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
          )
          cfg.users
      );
    };
  };

  defaultModule = {
    options.jvf.wrappers = defaultOptions;

    config = {
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
    };
  };
in
if isDarwin then darwinModule else defaultModule
