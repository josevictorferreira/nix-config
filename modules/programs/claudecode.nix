{ lib
, pkgs
, config
, username
, ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.claudecode;

  aiTools = import ../common/ai-tools { inherit lib pkgs; };

  mkMdConfigs =
    prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = value;
      })
      attrset;
in
{
  options.jvf.programs.claudecode = {
    enable = lib.mkEnableOption "Install claude-code router and write per-user ~/.claude-code-router/config.json";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    settings = lib.mkOption {
      type = json.type;
      default = {
        LOG = true;
        HOST = "127.0.0.1";
        PORT = 3456;
        API_TIMEOUT_MS = 600000;
        NON_INTERACTIVE_MODE = false;
        APIKEY = "local-dev";
        Providers = [
          {
            name = "openrouter";
            api_base_url = "https://openrouter.ai/api/v1/chat/completions";
            api_key = "\${OPENROUTER_API_KEY_CODE_AGENT}";
            models = [
              # In, Out
              "anthropic/claude-sonnet-4.5" # $3, $15
              "anthropic/claude-haiku-4.5" # $1, $5
              "google/gemini-2.5-flash-image" # $0.3, $2.5
              "google/gemini-2.5-flash-lite:online" # $0.1, $0.4
              "google/gemini-2.5-pro" # $1.25, $10
              "moonshotai/kimi-k2-0905" # $0.39, $1.90
              "moonshotai/kimi-k2-0905:exacto" # $0.60, $2.50
              "moonshotai/kimi-k2" # $0.14, $2.49
              "qwen/qwen3-coder-480b" # $0.22, $0.95
              "qwen/qwen3-235b-a22b-2507" # $0.08, $0.55
              "x-ai/grok-4-fast" # $0.20, $0.50
              "x-ai/grok-code-fast-1" # $0.20, $1.50
              "x-ai/grok-4" # $3, $15
              "z-ai/glm-4.6" # $0.40, $1.75
              "z-ai/glm-4.6:exacto" # $0.60, $1.90
              "minimax/minimax-m2:free" # $0, $0
              "openai/gpt-oss-120b:exacto" # $0.04, $0.40
              "deepseek/deepseek-v3.1-terminus:exacto" # $0.27, $1
              "deepseek/deepseek-v3.2-exp" # $0.27, $0.40
              "moonshotai/kimi-k2-thinking" # $0.60, $2.50
              "google/gemini-3-pro-preview"
              "openai/gpt-5.1-codex-max"
            ];
            transformer = {
              use = [ "openrouter" ];
            };
          }
        ];
        Router = {
          default = "openrouter,openai/gpt-5.1-codex-max";
          background = "openrouter,openai/gpt-oss-120b:exacto";
          think = "openrouter,moonshotai/kimi-k2-thinking";
          longContext = "openrouter,openai/gpt-5.1-codex-max";
          webSearch = "openrouter,google/gemini-2.5-flash-lite:online";
          image = "openrouter,google/gemini-2.5-flash-image";
          longContextThreshold = 250000;
        };
      };
      description = "Settings written to ~/.claude-code-router/config.json";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs = {
      claude = {
        packages = [
          pkgs.claude-code
        ];
        configPath = ".claude";
        configs = lib.mkMerge [
          (mkMdConfigs "agents" aiTools.agents)
          (mkMdConfigs "commands" aiTools.commands)
        ];
      };
      claude-code-router = {
        packages = [
          pkgs.claude-code-router
        ];
        configPath = ".claude-code-router";
        configs = {
          "config.json" = cfg.settings;
        };
      };
    };
  };
}
