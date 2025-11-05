{ lib
, pkgs
, generators
, ...
}:

let
  clonerepoOnce =
    { username
    , group
    , repo
    , targetDir
    ,
    }:
    {
      supportsDryActivation = true;
      text = ''
        set -euo pipefail
        if [ ! -d "${targetDir}/.git" ]; then
          ${pkgs.coreutils}/bin/mkdir -p "${targetDir}"
          ${pkgs.coreutils}/bin/chown -R ${username}:${group} "${targetDir}"
          GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
          ${pkgs.util.linux}/bin/runuser -u ${username} -- \
            ${pkgs.git}/bin/git clone --depth=1 ${repo} "${targetDir}"
        fi
      '';
    };

  getFileExtension =
    fileName:
    let
      parts = builtins.split "\\." fileName;
      extension =
        if builtins.length parts > 1 then (builtins.elemAt parts (builtins.length parts - 1)) else "";
    in
    extension;

  # importModulesInDir: Automatically discover and import all .nix modules in a directory
  #
  # WHAT IT DOES:
  # - Scans a directory for all .nix files
  # - Filters out "default.nix" (to prevent circular imports)
  # - Returns a list of targetDirs to import in your configuration
  #
  # WHAT IT NEEDS:
  # - `dir`: A directory targetDir (e.g., ./modules, ./roles)
  # - Returns: List of file targetDirs ready for the `imports` attribute
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
      nixFileNames = lib.filter
        (
          fileName: (lib.strings.hasSuffix ".nix" fileName) && (fileName != "default.nix")
        )
        allFileNames;
    in
    # Convert filenames to full targetDirs by prepending the directory
    lib.map (fileName: dir + "/${fileName}") nixFileNames;

  # mkConfigDir: Generate a configuration directory with structured file content
  #
  # WHAT IT DOES:
  # - Creates a directory containing configuration files with generated content
  # - Supports multiple formats: YAML, INI, and raw text
  # - Uses Nix store derivations for reproducible configuration files
  # - Returns a targetDir that can be used as a configuration directory
  #
  # WHAT IT NEEDS:
  # - `name`: Directory name (used in derivation naming)
  # - `files`: Attribute set where keys are file targetDirs and values are specs:
  #   - `type`: "yaml", "ini", or omitted for raw text
  #   - `content`: The actual configuration data (attrset for YAML/INI, string for text)
  # - Returns: targetDir to generated configuration directory
  #
  # WHY THIS EXISTS:
  # - Eliminates manual file creation for dynamic configurations
  # - Ensures configuration files are reproducible and version-controlled
  # - Provides type-safe generation of complex config formats
  # - Standardizes configuration management across the entire system
  #
  # USAGE EXAMPLE:
  # myAppConfig = mkConfigDir "myapp-config" {
  #     "config.yaml" = { key = "value"; nested = { setting = true; }; };
  #     "settings.ini" = { section = { option = "value"; }; };
  #   };
  # };
  mkConfigDir =
    name: files:
    pkgs.linkFarm name (
      lib.mapAttrsToList
        (fileName: fileContent: {
          name = fileName;
          targetDir = pkgs.writeText fileName (
            generators.toFileFormatStr (getFileExtension fileName) fileContent
          );
        })
        files
    );

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
  # - `configtargetDir`: targetDir within the derivation to the config files (e.g., "/share/nvim-config")
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
  #   configtargetDir = "/share/myapp-config";
  #   targetDir = "myapp";
  #   username = "josevictor";
  #   isDarwin = false;
  #   description = "MyApp configuration";
  # }
  createConfigLinks =
    { derivation
    , configtargetDir
    , targetDir
    , username
    , isDarwin ? false
    , description ? targetDir
    ,
    }:
    let
      userHome = if isDarwin then "/Users/${username}" else "/home/${username}";
      derivationConfigtargetDir = "${derivation}${configtargetDir}";
    in
    pkgs.writeScript "setup-${targetDir}-config" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      USER_HOME="${userHome}"
      TARGET_DIR="''${USER_HOME}/.config/${targetDir}"
      DERIVATION_CONFIG="${derivationConfigtargetDir}"
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

      chown -R ${username}:users "''${TARGET_DIR}"

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
  # - `configtargetDir`: targetDir within derivation to config files
  # - `targetDir`: Target config directory name
  # - Returns: Derivation with symlinked config structure
  #
  # USAGE EXAMPLE:
  # home.file.".config/nvim".source = createConfigLinksDerivation {
  #   derivation = neovimConfigDerivation;
  #   configtargetDir = "/share/nvim-config";
  #   targetDir = "nvim";
  # };
  createConfigLinksDerivation =
    { derivation
    , configtargetDir
    , targetDir
    ,
    }:
    let
      sourcetargetDir = "${derivation}${configtargetDir}";
    in
    pkgs.runCommand "${targetDir}-config-links"
      {
        nativeBuildInputs = [ pkgs.coreutils ];
        inherit sourcetargetDir targetDir;
      }
      ''
        mkdir -p $out
        ln -s $sourcetargetDir $out/${targetDir}
        echo "Created config symlink: $out/${targetDir} -> $sourcetargetDir"
      '';

  # cloneOnceText: Generate a script to clone a git repository once (idempotent)
  #
  # WHAT IT DOES:
  # - Creates a bash script fragment that clones a git repo if it doesn't exist
  # - Uses SSH with strict host key checking for security
  # - Runs as the specified user with proper ownership
  # - Supports both NixOS and nix-darwin systems
  #
  # WHAT IT NEEDS:
  # - `pkgs`: Package set for dependencies
  # - `repo`: Git repository URL (SSH format recommended)
  # - `user`: Username to run git clone as
  # - `group`: Group name for file ownership (optional, defaults to user)
  # - `home`: Home directory path (optional, auto-detected based on platform)
  # - `rel`: Relative path from home to clone directory
  # - `isDarwin`: Boolean indicating if this is for macOS (optional, defaults to false)
  #
  # WHY THIS EXISTS:
  # - Standardizes git repository cloning across the configuration
  # - Provides idempotent cloning (won't re-clone existing repos)
  # - Handles platform differences between NixOS and nix-darwin
  # - Ensures proper user ownership and permissions
  #
  # USAGE EXAMPLE:
  # cloneOnceText {
  #   pkgs = pkgs;
  #   repo = "git@github.com:user/dotfiles.git";
  #   user = "josevictor";
  #   group = "users";
  #   home = "/home/josevictor";
  #   rel = ".config/nvim";
  #   isDarwin = false;
  # }
  cloneOnceText =
    { pkgs
    , repo
    , user
    , group ? user
    , home
    , rel
    , isDarwin ? false
    ,
    }:
    let
      targetDir = "${home}/${rel}";
      # Use appropriate command for running as user on different platforms
      runAsUserCmd =
        if isDarwin then
          "${pkgs.sudo}/bin/sudo -u ${user}"
        else
          "${pkgs.util-linux}/bin/runuser -u ${user} --";
    in
    ''
      # Clone ${repo} to ${targetDir} if it doesn't exist
      if [ ! -d "${targetDir}/.git" ]; then
        echo "Cloning ${repo} to ${targetDir}..."
        ${pkgs.coreutils}/bin/mkdir -p "${targetDir}"
        ${pkgs.coreutils}/bin/chown -R ${user}:${group} "${targetDir}"
        GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
        ${runAsUserCmd} ${pkgs.git}/bin/git clone --depth=1 ${repo} "${targetDir}"
      else
        echo "Repository already exists at ${targetDir}, skipping clone..."
      fi
    '';

in
{
  inherit
    importModulesInDir
    mkConfigDir
    createConfigLinks
    createConfigLinksDerivation
    cloneOnceText
    ;
}
