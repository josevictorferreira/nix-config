{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.neovim;
in
{
  options.jvf.programs.neovim = {
    enable = lib.mkEnableOption "neovim, a hyperextensible text editor";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the neovim configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.neovim
      # Package and plugins dependencies
      pkgs.fzf
      pkgs.ripgrep
      pkgs.fd
      pkgs.gcc
      pkgs.tree-sitter
      pkgs.glibc
      pkgs.glibc.dev
      pkgs.pkg-config
    ];

    system.activationScripts.neovim-config = lib.stringAfter [ "users" ] ''
      set -euo pipefail
      user="${cfg.username}"
      home="$(getent passwd "$user" | cut -d: -f6 || true)"
      if [ -n "$home" ] && [ -d "$home" ]; then
        config_dir="$home/.config/nvim"

        # Check if the config directory already exists and has content
        if [ ! -d "$config_dir" ] || [ -z "$(ls -A "$config_dir" 2>/dev/null || true)" ]; then
          echo "Cloning neovim configuration for user '$user'..."

          # Create parent directory if it doesn't exist
          mkdir -p "$home/.config"

          # Clone the repository using SSH
          ${pkgs.git}/bin/git clone git@github.com:josevictorferreira/.nvim "$config_dir" || {
            echo "Failed to clone neovim configuration repository"
            exit 1
          }

          # Set proper ownership
          chown -R "$user:$(id -gn "$user" 2>/dev/null || echo users)" "$config_dir"

          echo "Neovim configuration cloned successfully"
        else
          echo "Neovim configuration already exists for user '$user', skipping clone"
        fi
      else
        echo "neovim-config: user '$user' not found or has no home directory" >&2
      fi
    '';
  };
}
