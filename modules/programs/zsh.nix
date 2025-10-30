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
  cfg = config.jvf.programs.zsh;
  zshConfig = pkgs.fetchFromGitHub {
    owner = "josevictorferreira";
    repo = ".zsh";
    rev = "main";
    sha256 = "sha256-GWFV1nMu1FbENfYD+awbxGrRyuz/MxrFnuSxXIf5xJg=";
  };

  zshConfigDerivation = pkgs.stdenv.mkDerivation {
    pname = "josevictor-zsh-config";
    version = "1.0.0";

    src = zshConfig;

    installPhase = ''
      mkdir -p $out/share/zsh-config
      cp -r . $out/share/zsh-config/
    '';

    meta = with lib; {
      description = "Zsh configuration for josevictorferreira";
      homepage = "https://github.com/josevictorferreira/.zsh";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  setupZshConfig = jvfLib.filesystem.createConfigLinks {
    derivation = zshConfigDerivation;
    configPath = "/share/zsh-config";
    targetDir = "zsh";
    username = cfg.username;
    inherit isDarwin;
    description = "Zsh configuration";
  };
in
{
  options.jvf.programs.zsh = {
    enable = lib.mkEnableOption "zsh, a powerful shell with advanced features";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the zsh configuration";
    };
    useDerivationConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the derivation-based zsh configuration from GitHub";
    };
    setAsDefaultShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to set zsh as the default shell for the user";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.zsh
      pkgs.fzf
      pkgs.ripgrep
      pkgs.direnv
    ]
    ++ lib.optionals cfg.useDerivationConfig [
      zshConfigDerivation
    ];

    users.users.${cfg.username} = lib.mkIf cfg.setAsDefaultShell {
      shell = pkgs.zsh;
    };

    environment.etc."skel/.zshrc".text = lib.mkIf isNixOS ''
      export K9S_CONFIG_DIR="$HOME/.config/k9s"
      eval "$(direnv hook zsh)"
      source $HOME/.config/zsh/init.zsh
    '';

    systemd.services.setup-zsh-config = lib.mkIf (cfg.useDerivationConfig && isNixOS) {
      description = "Setup Zsh configuration from derivation";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = "${setupZshConfig}";
      };
    };

    system.activationScripts.setup-zsh-config = lib.mkIf cfg.useDerivationConfig ''
      echo "Setting up Zsh configuration..."
      ${setupZshConfig}
    '';
  };
}
