{ ... }:
{
  config.jvf.programs.opencode.settings.provider = {
    # "llm-proxy" = {
    #   npm = "@ai-sdk/openai-compatible";
    #   name = "LLM Proxy";
    #   options = {
    #     baseURL = "http://127.0.0.1:18000/v1";
    #     apiKey = "{env:LLM_PROXY_API_KEY}";
    #   };
    #   models = {
    #     "antigravity/claude-opus-4-5" = {
    #       name = "Antigravity - Claude Opus 4.5";
    #     };
    #     "antigravity/gemini-3-pro-preview" = {
    #       name = "Antigravity - Gemini 3 Pro Preview";
    #     };
    #     "gemini/gemini-3-pro-preview" = {
    #       name = "Gemini - Gemini 3 Pro Preview";
    #     };
    #     "antigravity/claude-sonnet-4-5" = {
    #       name = "Antigravity - Claude Sonnet 4.5";
    #     };
    #     "gemini/gemini-2.5-pro" = {
    #       name = "Gemini - Gemini 2.5 Pro";
    #     };
    #     "gemini/gemini-3-flash-preview" = {
    #       name = "Gemini - Gemini 3 Flash Preview";
    #     };
    #     "minimax/MiniMax-M2.1" = {
    #       name = "Minimax - Minimax M2.1";
    #     };
    #     "openrouter/minimax/minimax-m2.1" = {
    #       name = "Openrouter - Minimax M2.1";
    #     };
    #     "minimax/MiniMax-M2" = {
    #       name = "Minimax - Minimax M2";
    #     };
    #     "openrouter/minimax/minimax-m2" = {
    #       name = "Openrouter - Minimax M2";
    #     };
    #     "openrouter/moonshotai/kimi-k2-thinking" = {
    #       name = "Openrouter - Kimi K2 Thinking";
    #     };
    #     "openrouter/moonshotai/kimi-k2-0905:exacto" = {
    #       name = "Openrouter - Kimi K2 0905";
    #     };
    #     "zai/glm-4.7" = {
    #       name = "Z-AI - GLM 4.7";
    #     };
    #     "openrouter/z-ai/glm-4.7" = {
    #       name = "Openrouter - GLM 4.7";
    #     };
    #     "zai/glm-4.6" = {
    #       name = "Z-AI - GLM 4.6";
    #     };
    #     "openrouter/z-ai/glm-4.6:exacto" = {
    #       name = "Openrouter - GLM 4.6";
    #     };
    #     "openrouter/openai/gpt-oss-120b:exacto" = {
    #       name = "Openrouter - GPT OSS 120b";
    #     };
    #     "zai/glm-4.5-air" = {
    #       name = "Z-AI - GLM 4.5 Air";
    #     };
    #   };
    # };

    local = {
      npm = "@ai-sdk/openai-compatible";
      name = "Local";
      options = {
        baseURL = "http://10.10.10.10:1234/v1";
      };
      models = {
        "nvidia_orchestrator-8b" = {
          name = "NVIDIA Orchestrator 8B";
        };
      };
    };

    openrouter = {
      npm = "@ai-sdk/anthropic";
      name = "OpenRouter";
      options = {
        baseURL = "https://openrouter.ai/api";
        apiKey = "{env:OPENROUTER_API_KEY_CODE_AGENT}";
      };
      models = {
        "xiaomi/mimo-v2-flash" = {
          name = "Xiaomi Mimo V2 Flash";
        };
      };
    };

    minimax = {
      npm = "@ai-sdk/anthropic";
      name = "Minimax";
      options = {
        baseURL = "https://api.minimax.io/anthropic/v1";
        apiKey = "{env:MINIMAX_API_KEY}";
      };
      models = {
        "MiniMax-M2" = {
          name = "Minimax M2";
        };
        "MiniMax-M2.1" = {
          name = "Minimax M2.1";
        };
      };
    };

    moonshotai = {
      npm = "@ai-sdk/anthropic";
      name = "Moonshot AI";
      options = {
        baseURL = "https://api.kimi.com/coding/v1";
        apiKey = "{env:KIMI_API_KEY}";
      };
      models = {
        "kimi-k2-thinking" = {
          name = "Kimi K2 Thinking";
        };
        "kimi-k2-0711-preview" = {
          name = "Kimi K2 0711 Preview";
        };
      };
    };

    zai-coding-plan = {
      npm = "@ai-sdk/anthropic";
      options = {
        baseURL = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "{env:Z_AI_API_KEY}";
      };
      models = {
        "glm-4.7" = {
          name = "GLM-4.7";
          variants = {
            reasoning = {
              reasoningEffort = "high";
              thinking.type = "enabled";
              fast.disabled = true;
              max_tokens = 4096;
              temperature = 1.0;
              clear_thinking = false;
            };
            fast = {
              reasoningEffort = "low";
              textVerbosity = "low";
              thinking.type = "disabled";
              temperature = 0.4;
              clear_thinking = false;
            };
          };
        };
        "glm-4.7-flashx" = {
          name = "GLM-4.7 FlashX";
        };
      };
    };

    google = {
      npm = "@ai-sdk/google";
      models = {
        "antigravity-gemini-3-pro-low" = {
          name = "Gemini 3 Pro Low (Antigravity)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-gemini-3-pro-high" = {
          name = "Gemini 3 Pro High (Antigravity)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-gemini-3-flash" = {
          name = "Gemini 3 Flash (Antigravity)";
          limit = { context = 1048576; output = 65536; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "gemini-3-pro-low" = {
          name = "Gemini 3 Pro Low (Gemini)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "gemini-3-pro-high" = {
          name = "Gemini 3 Pro High (Gemini)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "gemini-3-flash" = {
          name = "Gemini 3 Flash (Gemini)";
          limit = { context = 1048576; output = 65536; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5" = {
          name = "Claude Sonnet 4.5 (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5-thinking-low" = {
          name = "Claude Sonnet 4.5 Low (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5-thinking-medium" = {
          name = "Claude Sonnet 4.5 Medium (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5-thinking-high" = {
          name = "Claude Sonnet 4.5 High (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-opus-4-5-thinking-low" = {
          name = "Claude Opus 4.5 Low (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-opus-4-5-thinking-medium" = {
          name = "Claude Opus 4.5 Medium (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-opus-4-5-thinking-high" = {
          name = "Claude Opus 4.5 High (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
      };
    };
  };
}
