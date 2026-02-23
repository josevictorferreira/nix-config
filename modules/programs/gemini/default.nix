# Aspect: programs-gemini
# Installs Gemini CLI with auto-update wrapper and per-user config.
# Uses jvf.wrappers for config management.
# Depends on inputs.lib.aiTools for TOML/skill config generation.
{ ... }:
let
  mkGeminiOptions =
    { config, lib, pkgs, ... }:
    let
      json = pkgs.formats.json { };
    in
    {
      options.jvf.programs.gemini = {
        enable = lib.mkEnableOption "Install gemini-cli and write per-user ~/.gemini/config.json";

        antigravity.enable = lib.mkEnableOption "Install Antigravity Tools (Gemini CLI companion)";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };

        baseRules = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "A set of base rules to apply to the Gemini configuration";
        };

        agents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Agents to install as commands (Gemini CLI doesn't have native agents, so they become commands)";
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Skills to install into the configuration (string prompts or structured objects)";
        };

        commands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Commands to install into the configuration (string prompts or structured objects)";
        };

        mcps = lib.mkOption {
          type = lib.types.attrsOf json.type;
          default = { };
          description = "MCP tools to install into the configuration (structured objects)";
        };

        settings = lib.mkOption {
          type = json.type;
          default = { };
          description = "Settings written to ~/.gemini/settings.json";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      json = pkgs.formats.json { };
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
      imports = [ mkGeminiOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs.gemini.settings = {
          general.previewFeatures = true;
          general.vimMode = true;
          general.preferredEditor = "nvim";
          general.checkpointing.enabled = true;
          general.enablePromptCompletion = true;
          mcp = lib.mkDefault cfg.mcps;
          ui.theme = "Dracula";
          context.fileName = [
            "CLAUDE.md"
            "AGENTS.md"
            "GEMINI.md"
            "CONTEXT.md"
          ];
          tools.autoAccept = true;
          tools.enableHooks = true;
          tools.shell.showCOlor = true;
          tools.shell.pager = "bcat";
          tools.mcp.allowed = builtins.attrNames cfg.mcps;
          security.enablePermanentToolApproval = true;
          privacy.usageStatisticsEnabled = true;
          experimental.enableAgents = true;
          experimental.jitContext = true;
          experimental.skills = true;
          experimental.introspectionAgentSettings.enabled = true;
          telemetry.enabled = false;
        };

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
