# Aspect: programs-command-code
# Installs Command Code CLI with an auto-update wrapper.
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.command-code;

      npmPrefix = "$HOME/.npm-global";
      commandCodePackage = "command-code@latest";

      commandCodeFHS =
        if !isDarwin then
          pkgs.buildFHSEnv
            {
              name = "command-code-fhs";
              targetPkgs = pkgs: [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.openssl
                pkgs.nodejs_22
                pkgs.coreutils
              ];
              profile = ''
                export TMPDIR="''${TMPDIR:-$HOME/.cache/command-code-tmp}"
                mkdir -p "$TMPDIR"
              '';
              runScript = "${pkgs.writeShellScript "command-code-runner" ''
              exec "$HOME/.npm-global/bin/cmd" "$@"
            ''}";
            }
        else
          null;

      commandCodeWrapper = pkgs.writeShellScriptBin "cmd" ''
        set -euo pipefail

        export PATH="${lib.makeBinPath [ pkgs.nodejs_22 ]}:$PATH"
        NPM_PREFIX="${npmPrefix}"
        NPM_BIN="$NPM_PREFIX/bin"
        VERSION_FILE="$NPM_PREFIX/.command-code-version"

        mkdir -p "$NPM_PREFIX"
        ${pkgs.nodejs_22}/bin/npm config set prefix "$NPM_PREFIX" 2>/dev/null || true

        LATEST_VERSION=$(${pkgs.nodejs_22}/bin/npm view "${commandCodePackage}" version 2>/dev/null || echo "unknown")
        CURRENT_VERSION=""
        if [ -f "$VERSION_FILE" ]; then
          CURRENT_VERSION=$(cat "$VERSION_FILE")
        fi

        if [ ! -x "$NPM_BIN/cmd" ] || [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
          echo "Installing/updating command-code (${commandCodePackage})..."
          echo "  Current: ''${CURRENT_VERSION:-not installed}"
          echo "  Latest:  $LATEST_VERSION"
          ${pkgs.nodejs_22}/bin/npm install -g "${commandCodePackage}"
          echo "$LATEST_VERSION" > "$VERSION_FILE"
        fi

        export PATH="$NPM_BIN:$PATH"
        ${
          if !isDarwin then
            ''
              exec "${commandCodeFHS}/bin/command-code-fhs" "$@"
            ''
          else
            ''
              exec "$NPM_BIN/cmd" "$@"
            ''
        }
      '';
    in
    {
      options.jvf.programs.command-code = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing Command Code to.";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.cmd.packages = [
          commandCodeWrapper
        ];
      };
    };
in
{
  flake.modules.nixos.programs-command-code = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-command-code = mkConfig { isDarwin = true; };
}
