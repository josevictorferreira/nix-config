# config/provider.nix - AI provider configurations for OpenCode
_: {
  config.jvf.programs.opencode.settings.provider = {
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
        baseURL = "https://openrouter.ai/api/v1";
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
        "MiniMax-M2.5" = {
          name = "Minimax M2.5";
        };
      };
    };

    moonshotai = {
      npm = "@ai-sdk/anthropic";
      name = "Moonshot AI";
      options = {
        baseURL = "https://api.moonshot.ai/anthropic";
        apiKey = "{env:KIMI_API_KEY}";
      };
    };

    zai-coding-plan = {
      npm = "@ai-sdk/openai-compatible";
      options = {
        baseURL = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "{env:Z_AI_API_KEY}";
      };
      models = {
        "glm-5" = {
          name = "GLM-5";
          variants = {
            thinker = {
              name = "GLM-5 Deep Thinker";
              reasoningEffort = "high";
              thinking = {
                type = "enabled";
              };
              max_tokens = 4096;
              temperature = 1.0;
            };
            fast = {
              name = "GLM-5 Fast";
              reasoningEffort = "low";
              textVerbosity = "low";
              thinking.type = "disabled";
              temperature = 0.1;
              clear_thinking = false;
            };
          };
        };
        "glm-4.7" = {
          name = "GLM-4.7";
          variants = {
            thinker = {
              name = "GLM-4.7 Deep Thinker";
              reasoningEffort = "high";
              thinking = {
                type = "enabled";
              };
              max_tokens = 4096;
              temperature = 1.0;
            };
            fast = {
              name = "GLM-4.7 Fast";
              reasoningEffort = "low";
              textVerbosity = "low";
              thinking.type = "disabled";
              temperature = 0.1;
              clear_thinking = false;
            };
          };
        };
        "glm-4.7-flash" = {
          name = "GLM-4.7 Flash";
        };
      };
    };
  };
}
