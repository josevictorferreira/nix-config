# Aspect: wrappers
# Wrapper script generation, config file materialization to $HOME/.config, and
# per-user program environment management.
# NixOS: per-user activation scripts with supportsDryActivation.
# Darwin: postActivation script for all users.
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

            # Check if a path is a directory by checking for file extension
            # Files typically have extensions, directories don't (for our use case)
            isLikelyFile =
              p:
              let
                name = baseNameOf (toString p);
                hasExtension = lib.hasInfix "." name;
              in
              hasExtension;

            # Check if a string looks like a nix store path
            isStorePath = x: builtins.isString x && lib.hasPrefix "/nix/store/" x;

            createStructuredConfig =
              fileName: fileValue:
              if builtins.isPath fileValue then
                let
                  # Skip directory check if path looks like a file (has extension)
                  shouldCheckIfDir = !isLikelyFile fileValue;
                  # Check if path is a directory by trying to read it
                  isDir =
                    if shouldCheckIfDir then
                      builtins.tryEval
                        (
                          if builtins.pathExists fileValue then
                            let
                              dirContents = builtins.readDir fileValue;
                            in
                            dirContents != { }
                          else
                            false
                        )
                    else
                      {
                        success = true;
                        value = false;
                      }; # Assume file if has extension
                  # If tryEval failed (e.g., readDir on a file), treat as file not directory
                  isDirValue = if isDir.success then isDir.value else false;
                  isProgramConfigDir =
                    isDir.success && isDirValue && (fileName == programName || fileName == "${programName}-config");
                in
                if isDir.success && isDirValue then
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
          home =
            config.users.users.${userName}.home
              or (if isDarwin then "/Users/${userName}" else "/home/${userName}");

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
          home =
            config.users.users.${userName}.home
              or (if isDarwin then "/Users/${userName}" else "/home/${userName}");
        in
        ''
          set -e
        ''
        + lib.concatStringsSep "\n" (
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
              in
              ''
                ${installWrapper}
              ''
            )
            (uCfg.programs or { })
        )
        + ''
          true
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

      # ── Translation layer: jvf.wrappers → jvf.home ────────────────────────────
      # For each program with configs and useDerivationConfig == false,
      # generate jvf.home.users.<u>.items entries.
      translatedHomeItems =
        let
          # Filter programs that need translation (configs != {} && !useDerivationConfig)
          programsNeedingTranslation =
            userName: uCfg:
            lib.filterAttrs (_: pCfg: pCfg.configs != { } && !(pCfg.useDerivationConfig or false)) (
              uCfg.programs or { }
            );
        in
        lib.mapAttrs
          (
            userName: uCfg:
              let
                entries = programsNeedingTranslation userName uCfg;
              in
              {
                items = lib.mapAttrs'
                  (
                    programName: pCfg:
                      let
                        wrapper = mkProgramWrapper {
                          inherit userName programName;
                          inherit (pCfg)
                            packages
                            command
                            env
                            configs
                            useDerivationConfig
                            configPath
                            ;
                        };
                        relPath = if pCfg.configPath != null then pCfg.configPath else ".config/${programName}";
                      in
                      lib.nameValuePair relPath {
                        kind = "dir";
                        mode = "copy";
                        source = wrapper.configDir;
                        preserve = pCfg.preserveFiles;
                        postInstall = pCfg.postInstall;
                      }
                  )
                  entries;
              }
          )
          cfg.users;

      # ── Conflict detection: translated items vs direct jvf.home items ────────
      # Check that no OTHER module has set the same path we're translating.
      # Conflict assertions deferred to T8 (self-reference issue with NixOS module merge)
      conflictAssertions = [ ];
    in
    {
      imports = [ mkWrappersOption ];

      config = lib.mkMerge (
        [
          userPackagesConfig
          {
            # Wire translated items into jvf.home.users
            jvf.home.users = lib.mapAttrs (_: v: { items = v.items; }) translatedHomeItems;
            assertions = conflictAssertions;
          }
        ]
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
