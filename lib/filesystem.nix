{
  lib,
  pkgs,
  generators,
  ...
}:

let
  # importModulesInDir: Automatically discover and import all .nix modules in a directory
  #
  # WHAT IT DOES:
  # - Scans a directory for all .nix files
  # - Filters out "default.nix" (to prevent circular imports)
  # - Returns a list of paths to import in your configuration
  #
  # WHAT IT NEEDS:
  # - `dir`: A directory path (e.g., ./modules, ./roles)
  # - Returns: List of file paths ready for the `imports` attribute
  #
  # WHY THIS EXISTS:
  # - Eliminates manual maintenance of import lists
  # - Prevents forgetting to add new modules to imports
  # - Keeps module organization clean and scalable
  # - Standardizes the pattern across the entire configuration
  #
  # USAGE EXAMPLE:
  # imports = importModulesInDir ./roles;
  importModulesInDir =
    dir:
    let
      # Get all filenames in the directory as attribute names
      allFileNames = builtins.attrNames (builtins.readDir dir);

      # Filter for .nix files, excluding default.nix to prevent circular imports
      # default.nix files typically contain the imports themselves
      nixFileNames = lib.filter (
        fileName: (lib.strings.hasSuffix ".nix" fileName) && (fileName != "default.nix")
      ) allFileNames;
    in
    # Convert filenames to full paths by prepending the directory
    lib.map (fileName: dir + "/${fileName}") nixFileNames;

  # mkConfigDir: Generate a configuration directory with structured file content
  #
  # WHAT IT DOES:
  # - Creates a directory containing configuration files with generated content
  # - Supports multiple formats: YAML, INI, and raw text
  # - Uses Nix store derivations for reproducible configuration files
  # - Returns a path that can be used as a configuration directory
  #
  # WHAT IT NEEDS:
  # - `name`: Directory name (used in derivation naming)
  # - `files`: Attribute set where keys are file paths and values are specs:
  #   - `type`: "yaml", "ini", or omitted for raw text
  #   - `content`: The actual configuration data (attrset for YAML/INI, string for text)
  # - Returns: Path to generated configuration directory
  #
  # WHY THIS EXISTS:
  # - Eliminates manual file creation for dynamic configurations
  # - Ensures configuration files are reproducible and version-controlled
  # - Provides type-safe generation of complex config formats
  # - Standardizes configuration management across the entire system
  #
  # USAGE EXAMPLE:
  # home.file.".config/myapp" = mkConfigDir {
  #   name = "myapp-config";
  #   files = {
  #     "config.yaml" = {
  #       type = "yaml";
  #       content = { key = "value"; nested = { setting = true; }; };
  #     };
  #     "settings.ini" = {
  #       type = "ini";
  #       content = { section = { option = "value"; }; };
  #     };
  #   };
  # };
  mkConfigDir =
    { name, files }:
    let
      # For each "relative path" -> spec, produce { name = relPath; path = storeFile; }
      entries = lib.mapAttrsToList (
        relPath: spec:
        let
          text = generators.toFileFormatStr spec;

          out = pkgs.writeText "${name}-${lib.replaceStrings [ "/" ] [ "-" ] relPath}" text;
        in
        {
          name = relPath; # destination inside the directory (can include subdirs like "skins/foo.yaml")
          path = out; # source store path
        }
      ) files;
    in
    pkgs.linkFarm name entries;

  #############################################################################
  #  2. mkConfigDirSymlink (New Signature)
  #  - Signature: `config: fsPath:`
  #  - The first argument is the `{ name, files }` attribute set.
  #  - The second argument is the string path for the symlink directory.
  #  - Reuses the refactored `mkConfigDir` above.
  #############################################################################
  mkConfigDirSymlink =
    config: fsPath:
    let
      # Generate the real config files in a dedicated store path.
      # `mkConfigDir` is called with the `config` attrset directly.
      configStorePath = mkConfigDir config;

      # Get the list of relative file paths to create symlinks for.
      relativeFilePaths = builtins.attrNames config.files;
    in
    # Create the final derivation which contains only the symlink tree.
    pkgs.runCommand "${config.name}-symlink-tree"
      {
        # Pass Nix variables to the builder's environment for use in the script.
        inherit relativeFilePaths configStorePath fsPath;
        nativeBuildInputs = [ pkgs.coreutils ]; # For `ln`, `mkdir`, `dirname`
      }
      ''
        # A robust shell script header is best practice.
        set -euo pipefail

        echo "--- Creating symlink tree for ${config.name} ---"

        # `relativeFilePaths` is a space-separated string; load into a bash array.
        declare -a file_paths=($relativeFilePaths)

        for relPath in "''${file_paths[@]}"; do
          # The full path to the source file in the Nix store.
          local src_file="$configStorePath/$relPath"
          # The full path for the symlink we want to create inside the new package.
          local dst_file="$out/$fsPath/$relPath"

          # Ensure the parent directory for the symlink exists.
          mkdir -p "$(dirname "$dst_file")"

          # Create the symlink pointing to the immutable store path.
          ln -s "$src_file" "$dst_file"

          echo "Linked: $dst_file -> $src_file"
        done

        echo "--- Symlink tree created successfully at $out ---"
      '';

  # createConfigLinks: Create a script that symlinks a derivation to a user's config directory
  #
  # WHAT IT DOES:
  # - Generates a bash script that safely creates symlinks from a derivation to user config
  # - Handles existing configurations (removes old ones, preserves correct symlinks)
  # - Supports both Darwin and Linux home directory structures
  # - Provides proper ownership handling for NixOS systems
  #
  # WHAT IT NEEDS:
  # - `derivation`: The derivation containing config files (must have a predictable structure)
  # - `configPath`: Path within the derivation to the config files (e.g., "/share/nvim-config")
  # - `targetDir`: Target directory name in user's config (e.g., "nvim", "git", "tmux")
  # - `username`: Username for home directory resolution
  # - `isDarwin`: Boolean for macOS vs Linux home directory structure
  # - `description`: Optional description for logging (defaults to targetDir)
  #
  # WHY THIS EXISTS:
  # - Standardizes config linking across all program modules
  # - Eliminates duplicate linking logic in each module
  # - Provides safe, idempotent configuration management
  # - Handles platform differences automatically
  #
  # USAGE EXAMPLE:
  # createConfigLinks {
  #   derivation = myAppConfigDerivation;
  #   configPath = "/share/myapp-config";
  #   targetDir = "myapp";
  #   username = "josevictor";
  #   isDarwin = false;
  #   description = "MyApp configuration";
  # }
  createConfigLinks =
    {
      derivation,
      configPath,
      targetDir,
      username,
      isDarwin ? false,
      description ? targetDir,
    }:
    let
      userHome = if isDarwin then "/Users/${username}" else "/home/${username}";
      derivationConfigPath = "${derivation}${configPath}";
    in
    pkgs.writeScript "setup-${targetDir}-config" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      USER_HOME="${userHome}"
      TARGET_DIR="''${USER_HOME}/.config/${targetDir}"
      DERIVATION_CONFIG="${derivationConfigPath}"
      DESCRIPTION="${description}"

      # Create .config directory if it doesn't exist
      mkdir -p "''${USER_HOME}/.config"

      # Check if target is already correctly linked
      if [ -L "''${TARGET_DIR}" ]; then
        CURRENT_TARGET=$(readlink "''${TARGET_DIR}")
        if [ "''${CURRENT_TARGET}" = "''${DERIVATION_CONFIG}" ]; then
          echo "''${DESCRIPTION} is already correctly linked, skipping..."
          exit 0
        fi
      fi

      # Remove existing config if it exists
      if [ -e "''${TARGET_DIR}" ]; then
        echo "Removing existing ''${DESCRIPTION}..."
        rm -rf "''${TARGET_DIR}"
      fi

      # Create symlink to the derivation
      echo "Creating symlink for ''${DESCRIPTION} to ''${TARGET_DIR}..."
      ln -sf "''${DERIVATION_CONFIG}" "''${TARGET_DIR}"

      ${lib.optionalString (!isDarwin) ''
        # Set proper ownership on NixOS
        chown -R ${username}:users "''${TARGET_DIR}"
      ''}

      echo "''${DESCRIPTION} installed successfully!"
    '';

  # createConfigLinksDerivation: Create a derivation that contains config symlinks
  #
  # WHAT IT DOES:
  # - Creates a derivation with symlinks from a source derivation to config structure
  # - Returns a derivation that can be directly used as a config directory
  # - More declarative alternative to the script-based approach
  #
  # WHAT IT NEEDS:
  # - `derivation`: Source derivation containing config files
  # - `configPath`: Path within derivation to config files
  # - `targetDir`: Target config directory name
  # - Returns: Derivation with symlinked config structure
  #
  # USAGE EXAMPLE:
  # home.file.".config/nvim".source = createConfigLinksDerivation {
  #   derivation = neovimConfigDerivation;
  #   configPath = "/share/nvim-config";
  #   targetDir = "nvim";
  # };
  createConfigLinksDerivation =
    {
      derivation,
      configPath,
      targetDir,
    }:
    let
      sourcePath = "${derivation}${configPath}";
    in
    pkgs.runCommand "${targetDir}-config-links"
      {
        nativeBuildInputs = [ pkgs.coreutils ];
        inherit sourcePath targetDir;
      }
      ''
        mkdir -p $out
        ln -s $sourcePath $out/${targetDir}
        echo "Created config symlink: $out/${targetDir} -> $sourcePath"
      '';

in
{
  inherit
    importModulesInDir
    mkConfigDir
    mkConfigDirSymlink
    createConfigLinks
    createConfigLinksDerivation
    ;
}
