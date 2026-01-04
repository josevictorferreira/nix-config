{ lib
, pkgs
, config
, username
, inputs
, ...
}:
let
  cfg = config.jvf.programs.droid;
  json = pkgs.formats.json { };
  isLinux = pkgs.stdenv.isLinux;

  droidFHS =
    if isLinux then
      pkgs.buildFHSEnv
        {
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
        } else null;

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

    ${if isLinux then ''
      exec "${droidFHS}/bin/droid-fhs" "$@"
    '' else ''
      exec "$LOCAL_DROID" "$@"
    ''}
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
    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.factory/settings.json";
    };
    baseRules = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "A set of base rules to apply to the OpenCode configuration.";
    };
    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Agents to install into the configuration (string prompts or structured objects)";
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
    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Skills to install into the configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.droid = {
      packages = [
        shellScriptBin
      ];
      configPath = ".factory";
      configs = lib.mkMerge [
        (inputs.lib.aiTools.mkClaudecodeMdConfigs config.jvf.aiTools.mcp "droids" cfg.agents)
        (inputs.lib.aiTools.mkClaudecodeMdConfigs config.jvf.aiTools.mcp "commands" cfg.commands)
        (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
        {
          "settings.json" = {
            mcpServers = cfg.mcps;
            customModels = [
              {
                model = "minimax/minimax-m2.1";
                displayName = "Minimax M2.1 [OpenRouter]";
                baseUrl = "https://openrouter.ai/api/v1";
                apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
              }
              {
                model = "z-ai/glm-4.7";
                displayName = "GLM 4.7 [OpenRouter]";
                baseUrl = "https://openrouter.ai/api/v1";
                apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
              }
              {
                model = "moonshotai/kimi-k2-thinking";
                displayName = "Kimi K2 Thinking [OpenRouter]";
                baseUrl = "https://openrouter.ai/api/v1";
                apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
              }
              {
                model = "moonshotai/kimi-k2-0905:exacto";
                displayName = "Minimax K2 0905 [OpenRouter]";
                baseUrl = "https://openrouter.ai/api/v1";
                apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
              }
              {
                model = "z-ai/glm-4.6:exacto";
                displayName = "GLM 4.6 [OpenRouter]";
                baseUrl = "https://openrouter.ai/api/v1";
                apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
              }
            ];
          };
        }
      ];
    };
  };
}
