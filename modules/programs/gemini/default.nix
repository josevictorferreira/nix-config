# Aspect: programs-gemini
# Installs Gemini CLI with auto-update wrapper and per-user config.
# Uses jvf.wrappers for config management.
# Depends on inputs.lib.aiTools for TOML/skill config generation.
_:
let
  # Import default settings generator
  mkDefaultSettings = import ./_/settings.nix;

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let

      cfg = config.jvf.programs.gemini;

      geminiFHS =
        if !isDarwin then
          pkgs.buildFHSEnv
            {
              name = "gemini-cli-fhs";
              targetPkgs = pkgs: [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.openssl
                pkgs.nodejs
                pkgs.ripgrep
                pkgs.coreutils
              ];
              profile = ''
                export TMPDIR="''${TMPDIR:-$HOME/.cache/gemini-tmp}"
                mkdir -p "$TMPDIR"
              '';
              runScript = "${pkgs.writeShellScript "gemini-cli-runner" ''
              exec "$HOME/.npm-global/bin/gemini" "$@"
            ''}";
            }
        else
          null;

      npmPrefix = "$HOME/.npm-global";
      geminiPackage = "@google/gemini-cli@nightly";

      shellScriptBin = pkgs.writeShellScriptBin "gemini" ''
        set -euo pipefail

        export PATH="${lib.makeBinPath [ pkgs.nodejs ]}:$PATH"
        NPM_PREFIX="${npmPrefix}"
        NPM_BIN="$NPM_PREFIX/bin"
        GEMINI_BIN_DIR="$HOME/.gemini/bin"
        VERSION_FILE="$NPM_PREFIX/.gemini-cli-version"

        # Setup npm global prefix in home directory
        mkdir -p "$NPM_PREFIX"
        mkdir -p "$GEMINI_BIN_DIR"
        ${pkgs.nodejs}/bin/npm config set prefix "$NPM_PREFIX" 2>/dev/null || true

        # Symlink ripgrep if needed
        if [ ! -e "$GEMINI_BIN_DIR/rg" ]; then
          ln -sf "${pkgs.ripgrep}/bin/rg" "$GEMINI_BIN_DIR/rg"
        fi

        # Get latest available version
        LATEST_VERSION=$(${pkgs.nodejs}/bin/npm view "${geminiPackage}" version 2>/dev/null || echo "unknown")

        # Get currently installed version
        CURRENT_VERSION=""
        if [ -f "$VERSION_FILE" ]; then
          CURRENT_VERSION=$(cat "$VERSION_FILE")
        fi

        # Install or update if version changed or not installed
        if [ ! -x "$NPM_BIN/gemini" ] || [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
          echo "Installing/updating gemini-cli (${geminiPackage})..."
          echo "  Current: ''${CURRENT_VERSION:-not installed}"
          echo "  Latest:  $LATEST_VERSION"
          ${pkgs.nodejs}/bin/npm install -g "${geminiPackage}"
          echo "$LATEST_VERSION" > "$VERSION_FILE"
        fi

        export PATH="$NPM_BIN:$GEMINI_BIN_DIR:$PATH"
        ${
          if !isDarwin then
            ''
              exec "${geminiFHS}/bin/gemini-cli-fhs" "$@"
            ''
          else
            ''
              exec "$NPM_BIN/gemini" "$@"
            ''
        }
      '';
    in
    {
      imports = [ ./options.nix ];

      config = {
        # Set default settings using imported generator
        jvf.programs.gemini.settings = lib.mkDefault (mkDefaultSettings {
          inherit (cfg) mcps;
        });

        jvf.wrappers.users.${cfg.username}.programs.gemini = {
          packages = [
            shellScriptBin
            pkgs.antigravity
          ];
          preserveFiles = [
            "antigravity"
            "history"
            "tmp"
            "google_accounts.json"
            "oauth_creds.json"
            "installation_id"
          ];
          configPath = ".gemini";
          configs = lib.mkMerge [
            (inputs.lib.aiTools.mkGeminiTomlConfigs (cfg.commands // cfg.agents))
            (inputs.lib.aiTools.mkSkillConfigs cfg.skills)
            {
              "settings.json" = cfg.settings;
              "GEMINI.md" = cfg.baseRules;
            }
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-gemini = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-gemini = mkConfig { isDarwin = true; };
}
