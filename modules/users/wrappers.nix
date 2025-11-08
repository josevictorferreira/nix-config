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
      let
        # Recursively collect all files in a directory, excluding .nix files
        # Returns a list of { name = "relative/path"; path = "/absolute/path"; }
        collectFilesRecursive =
          baseDir: subPath:
          let
            fullPath = baseDir + "/" + subPath;
            entries = builtins.readDir fullPath;
            results = lib.flatten (lib.mapAttrsToList
              (entryName: entryType:
                let
                  fullEntryPath = fullPath + "/" + entryName;
                  relativePath = if subPath == "" then entryName else subPath + "/" + entryName;
                in
                if entryType == "directory" then
                  collectFilesRecursive baseDir relativePath
                else if entryType == "regular" && ! (lib.hasSuffix ".nix" entryName) then
                  [{ name = relativePath; path = fullEntryPath; }]
                else
                  [ ])
              entries);
          in
          results;
      in
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
              # When directory contains the config files directly, use programName instead of fileName
              isProgramConfigDir = isDir.success && isDir.value && (fileName == programName || fileName == "${programName}-config");
            in
            if isDir.success && isDir.value then
            # It's a directory, recursively collect all files (excluding .nix files)
              {
                name = if isProgramConfigDir then programName else fileName;
                path = pkgs.linkFarm programName (collectFilesRecursive (toString fileValue) "");
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

                  # Copy directory recursively with proper ownership instead of symlinking
                  if [ -d "${wrapper.configDir}" ]; then
                    mkdir -p "${targetDir}"
                    # Check if there's a subdirectory with the same name as the program
                    if [ -d "${wrapper.configDir}/${programName}" ]; then
                      # Copy contents of the subdirectory directly
                      cp -r "${wrapper.configDir}/${programName}/"* "${targetDir}/" 2>/dev/null || true
                    else
                      # Copy all contents directly
                      cp -r ${wrapper.configDir}/* "${targetDir}/" 2>/dev/null || true
                    fi
                    chown -R ${userName} "${targetDir}"
                    chmod -R u+rw "${targetDir}"
                    find "${targetDir}" -type d -exec chmod 755 {} \;
                    find "${targetDir}" -type f -exec chmod 644 {} \;
                  else
                    # Single file - copy with proper permissions
                    mkdir -p "$(dirname "${targetDir}")"
                    cp ${wrapper.configDir} "${targetDir}"
                    chown ${userName} "${targetDir}"
                    chmod 644 "${targetDir}"
                  fi
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
