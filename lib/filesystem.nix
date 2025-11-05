{
  lib,
  pkgs,
  generators,
  ...
}:

let
  # Get the file extension from a fileName
  getFileExtension =
    fileName:
    let
      parts = builtins.split "\\." fileName;
      extension =
        if builtins.length parts > 1 then (builtins.elemAt parts (builtins.length parts - 1)) else "";
    in
    extension;

  # Retrieves a list of modules inside of a dir
  modulesInDir =
    dir:
    let
      allFileNames = builtins.attrNames (builtins.readDir dir);
      nixFileNames = lib.filter (
        fileName: (lib.strings.hasSuffix ".nix" fileName) && (fileName != "default.nix")
      ) allFileNames;
    in
    lib.map (fileName: dir + "/${fileName}") nixFileNames;

  # Generate a configuration directory with structured file content
  mkConfigDir =
    name: files:
    pkgs.linkFarm name (
      lib.mapAttrsToList (fileName: fileContent: {
        name = fileName;
        targetDir = pkgs.writeText fileName (
          generators.toFileFormatStr (getFileExtension fileName) fileContent
        );
      }) files
    );

  # Create a script that symlinks a derivation to a user's config directory
  createConfigLinks =
    {
      derivation,
      configtargetDir,
      targetDir,
      username,
      isDarwin ? false,
      description ? targetDir,
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

  # Create a derivation that contains config symlinks
  createConfigLinksDerivation =
    {
      derivation,
      configtargetDir,
      targetDir,
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

in
{
  inherit
    modulesInDir
    mkConfigDir
    createConfigLinks
    createConfigLinksDerivation
    ;
}
