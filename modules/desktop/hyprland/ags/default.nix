{
  config,
  lib,
  pkgs,
  configRoot,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.ags;
  # Use the module's own directory as the source for AGS configuration
  agsConfigDir = toString (pkgs.path + "/modules/desktop/hyprland/ags");
  username = config.users.defaultUser;
in
{
  options.jvf.desktop.hyprland.ags = {
    enable = lib.mkEnableOption "AGS - Awesome Hyprland Widgets";
    configDir = lib.mkOption {
      type = lib.types.path;
      default = agsConfigDir;
      description = "Path to AGS configuration directory in the module";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ags;
      description = "AGS package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # Create AGS config directory setup script
    system.activationScripts.ags-config = {
      deps = [
        "users"
        "directories"
      ];
      text = ''
        echo "Setting up AGS configuration..."

        # Get user's home directory
        USER_HOME=$(getent passwd ${username} | cut -d: -f6)
        TARGET_DIR="''${USER_HOME}/.config/ags"

        # Create target directory
        mkdir -p "''${TARGET_DIR}"

        # Remove existing symlink or directory
        if [ -L "''${TARGET_DIR}" ]; then
          rm -f "''${TARGET_DIR}"
        elif [ -d "''${TARGET_DIR}" ]; then
          rm -rf "''${TARGET_DIR}"
        fi

        # Copy all configuration files from the module directory
        if [ -d "${agsConfigDir}" ]; then
          # Copy all files and directories except default.nix
          find "${agsConfigDir}" -maxdepth 1 -mindepth 1 ! -name "default.nix" -exec cp -r {} "''${TARGET_DIR}/" \; 2>/dev/null || true
          echo "AGS configuration copied to ''${TARGET_DIR}"
        else
          echo "Warning: AGS config directory ${agsConfigDir} not found - creating empty config"
          # Create basic AGS config structure
          mkdir -p "''${TARGET_DIR}/user"
          echo '// AGS Configuration file' > "''${TARGET_DIR}/config.js"
          echo 'export default {};' >> "''${TARGET_DIR}/config.js"
          echo '// User options' > "''${TARGET_DIR}/user_options.js"
          echo 'export default {};' >> "''${TARGET_DIR}/user_options.js"
        fi

        # Set proper ownership
        chown -R ${username}:${username} "''${TARGET_DIR}" 2>/dev/null || true
        chmod -R 755 "''${TARGET_DIR}" 2>/dev/null || true
        find "''${TARGET_DIR}" -name "*.js" -exec chmod 644 {} \; 2>/dev/null || true
        find "''${TARGET_DIR}" -name "*.css" -exec chmod 644 {} \; 2>/dev/null || true

        echo "AGS setup completed"
      '';
    };

    # Add environment variables for AGS
    environment.sessionVariables = {
      AGS_CONFIG_DIR = "$HOME/.config/ags";
    };
  };
}
