{ lib
, pkgs
, config
, username
, ...
}:
let
  cfg = config.jvf.programs.droid;
  droidFHS = pkgs.buildFHSEnv {
    name = "droid-fhs";
    targetPkgs =
      pkgs: with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        ripgrep
        coreutils
      ];
    profile = ''
      export TMPDIR="''${TMPDIR:-$HOME/.cache/factory-tmp}"
      mkdir -p "$TMPDIR"
    '';
    runScript = "${pkgs.writeShellScript "droid-runner" ''
      exec "$HOME/.local/bin/droid" "$@"
    ''}";
  };
  shellScriptBin = pkgs.writeShellScriptBin "droid" ''
    set -euo pipefail

    INSTALL_URL="https://app.factory.ai/cli"
    LOCAL_BIN="$HOME/.local/bin"
    LOCAL_DROID="$LOCAL_BIN/droid"
    FACTORY_BIN_DIR="$HOME/.factory/bin"

    mkdir -p "$FACTORY_BIN_DIR"
    if [ ! -e "$FACTORY_BIN_DIR/rg" ]; then
      ln -sf "${pkgs.ripgrep}/bin/rg" "$FACTORY_BIN_DIR/rg"
    fi

    if [ ! -x "$LOCAL_DROID" ]; then
      mkdir -p "$LOCAL_BIN"
      PATH="$FACTORY_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
    fi

    exec "${droidFHS}/bin/droid-fhs" "$@"
  '';
in
{
  options.jvf.programs.droid = {
    enable = lib.mkEnableOption "Enable factory droid-cli program";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username to install the program";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.droid = {
      packages = [
        shellScriptBin
      ];
    };
  };
}
