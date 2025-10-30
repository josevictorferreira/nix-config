{
  lib,
  pkgs,
  config,
  username,
  isDarwin,
  isNixOS,
  jvfLib,
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

  setupNeovimConfig = jvfLib.filesystem.createConfigLinks {
    derivation = neovimConfigDerivation;
    configPath = "/share/nvim-config";
    targetDir = "nvim";
    username = cfg.username;
    inherit isDarwin;
    description = "Neovim configuration";
  };
in
{
  options.jvf.programs.neovim = {
    enable = lib.mkEnableOption "neovim, a hyperextensible text editor";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the neovim configuration";
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
        ExecStart = "${setupNeovimConfig}";
      };
    };

    system.activationScripts.setup-nvim-config = lib.mkIf cfg.useDerivationConfig ''
      echo "Setting up Neovim configuration..."
      ${setupNeovimConfig}
    '';
  };
}
