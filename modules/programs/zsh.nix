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

  # Create initial .zshrc file that sources the main config
  initialZshrcDerivation = pkgs.stdenv.mkDerivation {
    pname = "initial-zshrc";
    version = "1.0.0";

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share
      echo '# Initial zsh configuration' > $out/share/.zshrc
      echo '# This file sources the main zsh configuration from ~/.config/zsh/init.zsh' >> $out/share/.zshrc
      echo >> $out/share/.zshrc
      echo 'source $HOME/.config/zsh/init.zsh' >> $out/share/.zshrc
    '';
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

    system.activationScripts.setup-zshrc = lib.mkIf cfg.useDerivationConfig ''
      echo "Setting up initial .zshrc..."
      USER_HOME="${if isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}"}"
      ZSHRC_SOURCE="${initialZshrcDerivation}/share/.zshrc"
      ZSHRC_TARGET="$USER_HOME/.zshrc"

      # Create the home directory if it doesn't exist
      mkdir -p "$USER_HOME"

      # Only create .zshrc if it doesn't exist or is not a symlink to our source
      if [ ! -e "$ZSHRC_TARGET" ]; then
        echo "Creating initial .zshrc..."
        ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
        ${lib.optionalString (!isDarwin) "chown ${cfg.username}:users \"$ZSHRC_TARGET\""}
      elif [ -L "$ZSHRC_TARGET" ]; then
        CURRENT_TARGET=$(readlink "$ZSHRC_TARGET")
        if [ "$CURRENT_TARGET" != "$ZSHRC_SOURCE" ]; then
          echo "Updating .zshrc symlink..."
          rm -f "$ZSHRC_TARGET"
          ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
          ${lib.optionalString (!isDarwin) "chown ${cfg.username}:users \"$ZSHRC_TARGET\""}
        else
          echo ".zshrc is already correctly linked, skipping..."
        fi
      else
        echo ".zshrc exists but is not a symlink, preserving existing file..."
      fi
    '';
  };
}
