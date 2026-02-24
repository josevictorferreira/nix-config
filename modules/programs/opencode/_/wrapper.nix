# wrapper.nix - FHS environment and wrapper scripts for OpenCode
{ pkgs }:
let
  openCodeFHS = pkgs.buildFHSEnv {
    name = "opencode-fhs";
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
      export TMPDIR="''${TMPDIR:-$HOME/.cache/opencode-tmp}"
      mkdir -p "$TMPDIR"
    '';
    runScript = "${pkgs.writeShellScript "opencode-runner" ''
      exec "$HOME/.opencode/bin/opencode" "$@"
    ''}";
  };

  shellScriptBinLinux = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    INSTALL_URL="https://opencode.ai/install"
    OPENCODE_BIN_DIR="$HOME/.opencode/bin"

    if [ ! -x "$OPENCODE_BIN_DIR/opencode" ]; then
      mkdir -p "$OPENCODE_BIN_DIR"
      PATH="$OPENCODE_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
    fi

    exec "${openCodeFHS}/bin/opencode-fhs" "$@"
  '';

  shellScriptBinDarwin = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    INSTALL_URL="https://opencode.ai/install"
    OPENCODE_BIN_DIR="$HOME/.opencode/bin"
    OPENCODE_BIN="$OPENCODE_BIN_DIR/opencode"

    if [ ! -x "$OPENCODE_BIN" ]; then
      mkdir -p "$OPENCODE_BIN_DIR"
      PATH="$OPENCODE_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
    fi

    exec "$OPENCODE_BIN" "$@"
  '';
in
{
  inherit shellScriptBinLinux shellScriptBinDarwin;
}
