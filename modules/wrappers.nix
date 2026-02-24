# Aspect: wrappers
# Wrapper script generation, config file materialization to $HOME/.config, and
# per-user program environment management.
# NixOS: per-user activation scripts with supportsDryActivation.
# Darwin: postActivation script for all users.
{ ... }:
let
  # Shared option definition — identical for both platforms
  mkWrappersOption =
    { lib, ... }:
    {
      options.jvf.wrappers = {
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
                          preserveFiles = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [ ];
                            description = "List of files or directories to preserve from the previous configuration (copied from backup).";
                          };

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
                            type = lib.types.attrsOf (
                              lib.types.oneOf [
                                lib.types.path
                                lib.types.str
                                lib.types.attrs
                              ]
                            );
                            default = { };
                            description = ''
                              Configuration files. Keys are filenames, values are either:
                              - Path: copied as-is
                              - String: written as plain text
                              - Attrset: converted based on file extension (.json, .yaml, .toml, .ini)
                            '';
                          };

                          useDerivationConfig = lib.mkOption {
                            type = lib.types.bool;
                            default = false;
                            description = "Keep configs in derivation instead of symlinking to ~/.config/{name}/";
                          };

                          configPath = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = null;
                            description = ''
                              Custom path for config installation relative to $HOME.
                              If null, defaults to .config/{programName}.
                              Example: ".claude-code-router" installs to ~/.claude-code-router
                            '';
                          };

                          postInstall = lib.mkOption {
                            type = lib.types.lines;
                            default = "";
                            description = "Script to run after config installation.";
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
    };

  # Shared implementation logic, parameterized by platform
  mkWrappersConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
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
            collectFilesRecursive =
              baseDir: subPath:
              let
                fullPath = baseDir + "/" + subPath;
                entries = builtins.readDir fullPath;
                results = lib.flatten (
                  lib.mapAttrsToList
                    (
                      entryName: entryType:
                        let
                          fullEntryPath = fullPath + "/" + entryName;
                          relativePath = if subPath == "" then entryName else subPath + "/" + entryName;
                        in
                        if entryType == "directory" then
                          collectFilesRecursive baseDir relativePath
                        else if entryType == "regular" && !(lib.hasSuffix ".nix" entryName) then
                          [
                            {
                              name = relativePath;
                              path = fullEntryPath;
                            }
                          ]
                        else
                          [ ]
                    )
                    entries
                );
              in
              results;

            # Check if a value is a derivation (has outPath attribute)
            isDerivation = x: builtins.isAttrs x && x ? outPath;

            # Check if a string looks like a nix store path
            isStorePath = x: builtins.isString x && lib.hasPrefix "/nix/store/" x;

            createStructuredConfig =
              fileName: fileValue:
              if builtins.isPath fileValue then
                let
                  isDir = builtins.tryEval (
                    if builtins.pathExists fileValue then
                      let
                        dirContents = builtins.readDir fileValue;
                      in
                      dirContents != { }
                    else
                      false
                  );
                  isProgramConfigDir =
                    isDir.success && isDir.value && (fileName == programName || fileName == "${programName}-config");
                in
                if isDir.success && isDir.value then
                  {
                    name = if isProgramConfigDir then programName else fileName;
                    path = pkgs.linkFarm programName (collectFilesRecursive (toString fileValue) "");
                  }
                else
                  {
                    name = fileName;
                    path = fileValue;
                  }
              # Handle derivations (e.g., pkgs.runCommand results)
              else if isDerivation fileValue then
                {
                  name = fileName;
                  path = fileValue;
                }
              # Handle store path strings
              else if isStorePath fileValue then
                {
                  name = fileName;
                  path = fileValue;
                }
              else if builtins.isString fileValue then
                {
                  name = fileName;
                  path = pkgs.writeText "${programName}-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue;
                }
              else if builtins.isAttrs fileValue then
                let
                  ext = getFileExtension fileName;
                  content = inputs.lib.generators.toFileFormatStr ext fileValue;
                in
                {
                  name = fileName;
                  path = pkgs.writeText "${programName}-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" content;
                }
              else
                throw "Config value for ${fileName} must be either a path, string, or an attrset";
          in
          lib.mapAttrs createStructuredConfig configs;

      mkProgramWrapper =
        { userName
        , programName
        , packages
        , command ? null
        , env ? { }
        , configs ? { }
        , useDerivationConfig ? false
        , configPath ? null
        ,
        }:
        let
          home = if isDarwin then "/Users/${userName}" else "/home/${userName}";

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
          configTargetDir =
            if useDerivationConfig then
              null
            else
              "${home}/${if configPath != null then configPath else ".config/${programName}"}";
        };

      mkUserActivation =
        userName: uCfg:
        let
          home = if isDarwin then "/Users/${userName}" else "/home/${userName}";
        in
        lib.concatStringsSep "\n" (
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
                    configs
                    useDerivationConfig
                    configPath
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

                setupConfig =
                  if wrapper.configDir == null || (programCfg.useDerivationConfig or false) then
                    ""
                  else
                    let
                      targetDir = wrapper.configTargetDir;
                      darwinCopyDir = ''
                        find "${wrapper.configDir}" -mindepth 1 -maxdepth 1 -exec cp -rL {} "$TARGET_DIR/" \; 2>/dev/null || true
                      '';
                      linuxCopyDir = ''
                        if [ -d "${wrapper.configDir}/${programName}" ]; then
                          cp -rL "${wrapper.configDir}/${programName}/"* "$TARGET_DIR/" 2>/dev/null || true
                        fi
                        # Copy any other files/directories (excluding the program-named subdirectory), dereferencing symlinks
                        find "${wrapper.configDir}" -mindepth 1 -maxdepth 1 ! -name "${programName}" -exec cp -rL {} "$TARGET_DIR/" \; 2>/dev/null || true
                      '';
                    in
                    ''
                      echo "Setting up config for ${programName}..."
                      TARGET_PATH="${targetDir}"
                      TARGET_DIR="${targetDir}.tmp"

                      rm -rf "$TARGET_DIR"
                      mkdir -p "$TARGET_DIR"

                      # Copy all files from config directory, dereferencing symlinks
                      if [ -d "${wrapper.configDir}" ]; then
                        ${if isDarwin then darwinCopyDir else linuxCopyDir}
                        chown -R ${userName}:${if isDarwin then "staff" else "users"} "$TARGET_DIR"
                        chmod -R u+rw "$TARGET_DIR"
                        find "$TARGET_DIR" -type d -exec chmod 755 {} \;
                        find "$TARGET_DIR" -type f -exec chmod 644 {} \;
                      fi

                      # Check for changes
                      if [ -d "$TARGET_PATH" ] && diff -r -q "$TARGET_DIR" "$TARGET_PATH" >/dev/null 2>&1; then
                        echo "Config for ${programName} unchanged."
                        rm -rf "$TARGET_DIR"
                      else
                        # Atomic swap
                        BACKUP_DIR=""
                        if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                          echo "Backing up existing ${programName} config..."
                          rm -rf "$TARGET_PATH".backup.*

                          BACKUP_TIMESTAMP=$(date +%s)
                          BACKUP_DIR="$TARGET_PATH.backup.$BACKUP_TIMESTAMP"
                          mv "$TARGET_PATH" "$BACKUP_DIR"
                        fi

                        rm -rf "$TARGET_PATH"
                        mv "$TARGET_DIR" "$TARGET_PATH"

                        ${lib.optionalString (programCfg.preserveFiles != [ ]) ''
                          if [ -n "$BACKUP_DIR" ]; then
                            # Restore preserved files
                            ${lib.concatMapStringsSep "\n" (file: ''
                              if [ -e "$BACKUP_DIR/${file}" ]; then
                                echo "Restoring preserved file: ${file}..."
                                rm -rf "$TARGET_PATH/${file}"
                                cp -r "$BACKUP_DIR/${file}" "$TARGET_PATH/${file}"
                                # Fix ownership since activation scripts run as root
                                chown -R ${userName}:${if isDarwin then "staff" else "users"} "$TARGET_PATH/${file}"
                              fi
                            '') programCfg.preserveFiles}
                          fi
                        ''}

                        ${programCfg.postInstall}
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
        [ userPackagesConfig ]
        ++ lib.optional isDarwin {
          system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
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
