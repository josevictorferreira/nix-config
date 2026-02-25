# Default router settings for claude-code-router
# Pure data export - no module boilerplate
_:
{
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
        "anthropic/claude-sonnet-4.5"
        "anthropic/claude-haiku-4.5"
        "google/gemini-2.5-flash-image"
        "google/gemini-2.5-flash-lite:online"
        "google/gemini-2.5-pro"
        "moonshotai/kimi-k2-0905"
        "moonshotai/kimi-k2-0905:exacto"
        "moonshotai/kimi-k2"
        "qwen/qwen3-coder-480b"
        "qwen/qwen3-235b-a22b-2507"
        "x-ai/grok-4-fast"
        "x-ai/grok-code-fast-1"
        "x-ai/grok-4"
        "z-ai/glm-4.6"
        "z-ai/glm-4.6:exacto"
        "minimax/minimax-m2:free"
        "openai/gpt-oss-120b:exacto"
        "deepseek/deepseek-v3.1-terminus:exacto"
        "deepseek/deepseek-v3.2-exp"
        "moonshotai/kimi-k2-thinking"
        "google/gemini-3-pro-preview"
        "z-ai/glm-4.7"
        "qwen/qwen3.5-397b-a17b"
        "qwen/qwen3-coder-next"
        "stepfun/step-3.5-flash"
        "moonshotai/kimi-k2.5"
        "minimax/minimax-m2.5"
      ];
      transformer = {
        use = [ "openrouter" ];
      };
    }

    {
      name = "minimax";
      api_base_url = "https://api.minimax.io/anthropic/v1";
      api_key = "\${MINIMAX_API_KEY}";
      models = [
        "MiniMax-M2"
        "MiniMax-M2.1"
        "MiniMax-M2.5"
      ];
    }

    {
      name = "moonshotai";
      api_base_url = "https://api.moonshot.ai/anthropic";
      api_key = "\${KIMI_API_KEY}";
      models = [
        "kimi-k2.5"
      ];
    }

    {
      name = "zai";
      api_base_url = "https://api.z.ai/api/coding/paas/v4";
      api_key = "\${Z_AI_API_KEY}";
      models = [
        "glm-5"
        "glm-4.7"
      ];
    }
  ];
  Router = {
    default = "openrouter,moonshotai/kimi-k2.5";
    background = "openrouter,openai/gpt-oss-120b:exacto";
    think = "openrouter,moonshotai/kimi-k2.5";
    longContext = "openrouter,moonshotai/kimi-k2.5";
    webSearch = "openrouter,google/gemini-2.5-flash-lite:online";
    image = "openrouter,google/gemini-2.5-flash-image";
    longContextThreshold = 250000;
  };
  StatusLine = {
    enabled = true;
    currentStyle = "powerline";
    default = {
      modules = [ ];
    };
    powerline = {
      modules = [
        {
          type = "model";
          icon = "🤖";
          text = "{{model}}";
          color = "bright_yellow";
        }
        {
          type = "usage";
          icon = "📊";
          text = "{{inputTokens}} → {{outputTokens}}";
          color = "bright_magenta";
        }
        {
          type = "workDir";
          icon = "󰉋";
          text = "{{workDirName}}";
          color = "bright_blue";
        }
        {
          type = "gitBranch";
          icon = "🌿";
          text = "{{gitBranch}}";
          color = "bright_green";
        }
        {
          type = "speed";
          icon = "⚡";
          text = "{{tokenSpeed}}";
          color = "bright_green";
        }
        {
          type = "script";
          icon = "📜";
          text = "Script Module";
          color = "bright_cyan";
          scriptPath = "";
        }
      ];
    };
  };
}
