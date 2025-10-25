{ lib, pkgs, ... }:

{
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
      # Use mapAttrsToList to transform the input attrset into a list
      # suitable for pkgs.linkFarm.
      pathSpecs = lib.mapAttrsToList (path: spec: {
        inherit path;
        # For each file, create the corresponding derivation.
        # This is where we handle different content types.
        source =
          if spec.type == "yaml" then
            # Use writeText with the YAML generator.
            pkgs.writeText "${name}-${path}" (lib.generators.toYAML { } spec.content)
          else if spec.type == "ini" then
            # Use writeText with the INI generator.
            pkgs.writeText "${name}-${path}" (
              lib.generators.toINIWithGlobalSection { } { globalSection = spec.content; }
            )
          else
            # Default to raw text.
            pkgs.writeText "${name}-${path}" spec.content;
      }) files;
    in
    # pkgs.linkFarm is the perfect tool to build a directory from a list of sources.
    pkgs.linkFarm name pathSpecs;
}
