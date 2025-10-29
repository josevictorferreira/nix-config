{
  lib,
  pkgs,
  config,
  username,
  isDarwin,
  isNixOS,
  ...
}:
let
  cfg = config.jvf.programs.neovim;
  neovimConfig = pkgs.fetchFromGitHub {
    owner = "josevictorferreira";
    repo = ".nvim";
    rev = "main";
    sha256 = "sha256-E/A5H44u1ZgmMJ6PObzB2scsGar/kka1JrRFjK3UXd0=";
  };

  neovimConfigDerivation = pkgs.stdenv.mkDerivation {
    pname = "josevictor-nvim-config";
    version = "1.0.0";

    src = neovimConfig;

    installPhase = ''
      mkdir -p $out/share/nvim-config
      cp -r . $out/share/nvim-config/
    '';

    meta = with lib; {
      description = "Neovim configuration for josevictorferreira";
      homepage = "https://github.com/josevictorferreira/.nvim";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  createNeovimConfigLinks =
    {
      username,
      isDarwin ? false,
    }:
    let
      userHome = if isDarwin then "/Users/${username}" else "/home/${username}";
    in
    pkgs.writeScript "setup-nvim-config" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      USER_HOME="${userHome}"
      NVIM_CONFIG_DIR="''${USER_HOME}/.config/nvim"
      DERIVATION_CONFIG="${neovimConfigDerivation}/share/nvim-config"

      # Create .config directory if it doesn't exist
      mkdir -p "''${USER_HOME}/.config"

      # Remove existing nvim config if it exists (but not if it's already a symlink to our derivation)
      if [ -L "''${NVIM_CONFIG_DIR}" ]; then
        CURRENT_TARGET=$(readlink "''${NVIM_CONFIG_DIR}")
        if [ "''${CURRENT_TARGET}" = "''${DERIVATION_CONFIG}" ]; then
          echo "Neovim configuration is already correctly linked, skipping..."
          exit 0
        fi
      fi

      # Remove existing nvim config if it exists
      if [ -e "''${NVIM_CONFIG_DIR}" ]; then
        echo "Removing existing nvim config..."
        rm -rf "''${NVIM_CONFIG_DIR}"
      fi

      # Create symlink to the derivation
      echo "Creating symlink from derivation to ''${NVIM_CONFIG_DIR}..."
      ln -sf "''${DERIVATION_CONFIG}" "''${NVIM_CONFIG_DIR}"

      ${
        if isDarwin then
          ""
        else
          ''
            # Set proper ownership on NixOS
            chown -R ${username}:users "''${NVIM_CONFIG_DIR}"
          ''
      }

      echo "Neovim configuration installed successfully!"
    '';
in
{
  options.jvf.programs.neovim = {
    enable = lib.mkEnableOption "neovim, a hyperextensible text editor";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the neovim configuration";
    };
    generateSSHKey = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to generate an SSH key if one doesn't exist";
    };
    fallbackToHTTPS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to fall back to HTTPS clone if SSH clone fails";
    };
    useDerivationConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the derivation-based neovim configuration from GitHub";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.neovim
      pkgs.fzf
      pkgs.ripgrep
      pkgs.fd
      pkgs.gcc
      pkgs.tree-sitter
      pkgs.glibc
      pkgs.glibc.dev
      pkgs.pkg-config
      pkgs.openssh
    ]
    ++ lib.optionals cfg.useDerivationConfig [
      neovimConfigDerivation
    ];

    systemd.services.setup-nvim-config = lib.mkIf (cfg.useDerivationConfig && isNixOS) {
      description = "Setup Neovim configuration from derivation";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = "${createNeovimConfigLinks {
          inherit (cfg) username;
          inherit isDarwin;
        }}";
      };
    };

    system.activationScripts.setup-nvim-config = lib.mkIf cfg.useDerivationConfig ''
      echo "Setting up Neovim configuration..."
      ${createNeovimConfigLinks {
        inherit (cfg) username;
        inherit isDarwin;
      }}
    '';
  };
}
