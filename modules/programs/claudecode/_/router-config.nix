# Default router settings for claude-code-router
# Pure data export - no module boilerplate
_: {
  LOG = true;
  HOST = "127.0.0.1";
  PORT = 3456;
  API_TIMEOUT_MS = 600000;
  NON_INTERACTIVE_MODE = false;
  APIKEY = "local-dev";
  Providers = [
    {
      name = "alibaba-coding-plan";
      api_base_url = "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic/v1/messages";
      api_key = "\${ALIBABA_CODING_PLAN_API_KEY}";
      models = [
        "qwen3.6-plus"
        "qwen3.5-plus"
        "qwen3-max-2026-01-23"
        "qwen3-coder-next"
        "qwen3-coder-plus"
        "glm-5"
        "glm-4.7"
        "kimi-k2.5"
      ];
      transformer = {
        use = [ "Anthropic" ];
      };
    }
    {
      name = "openrouter";
      api_base_url = "https://openrouter.ai/api/v1/chat/completions";
      api_key = "\${OPENROUTER_API_KEY_CODE_AGENT}";
      models = [
      ];
      transformer = {
        use = [ "openrouter" ];
      };
    }

    {
      name = "kimi-for-coding";
      api_base_url = "https://api.kimi.com/coding/v1/messages";
      api_key = "\${KIMI_API_KEY}";
      models = [
        "kimi-for-coding"
      ];
      transformer = {
        use = [ "Anthropic" ];
      };
    }

    {
      name = "zai-coding-plan";
      api_base_url = "https://api.z.ai/api/anthropic/v1/messages";
      api_key = "\${Z_AI_API_KEY}";
      models = [
        "glm-5.1"
        "glm-5"
        "glm-4.7"
        "glm-5-turbo"
      ];
      transformer = {
        use = [ "Anthropic" ];
      };
    }

    {
      name = "opencode-go";
      api_base_url = "https://opencode.ai/zen/go";
      api_key = "\${OPENCODE_GO_API_KEY}";
      models = [
        "deepseek-v4-flash"
        "deepseek-v4-pro"
        "glm-5"
        "glm-5.1"
        "kimi-k2.5"
        "kimi-k2.6"
        "mimo-v2.5"
        "mimo-v2.5-pro"
        "qwen3.5-plus"
        "qwen3.6-plus"
      ];
      transformer = {
        use = [ "openrouter" ];
      };
    }
  ];
  Router = {
    default = "zai-coding-plan,glm-5.1";
    background = "alibaba-coding-plan,qwen3-coder-next";
    think = "kimi-for-coding,kimi-for-coding";
    longContext = "opencode-go,deepseek-v4-pro";
    webSearch = "openrouter,google/gemini-2.5-flash-lite:online";
    image = "opencode-go,qwen3.6-plus";
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
