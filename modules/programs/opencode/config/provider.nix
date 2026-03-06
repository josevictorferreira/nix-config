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
      options = {
        apiKey = "{env:OPENROUTER_API_KEY_CODE_AGENT}";
      };
    };

    inception = {
      npm = "@ai-sdk/openai-compatible";
      name = "Inception";
      options = {
        baseURL = "https://api.inceptionlabs.ai/v1";
        apiKey = "{env:INCEPTION_API_KEY}";
      };
      models = {
        "mercury-2" = {
          name = "Mercury 2";
          max_tokens = 16384;
        };
      };
    };

    bailian-coding-plan = {
      npm = "@ai-sdk/anthropic";
      name = "Model Studio Coding Plan";
      options = {
        baseURL = "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic/v1";
        apiKey = "{env:BAILIAN_CODING_PLAN_API_KEY}";
      };
      models = {
        "qwen3.5-plus" = {
          name = "Qwen3.5 Plus";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [
              "text"
            ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 1024;
            };
          };
        };
        "qwen3-max-2026-01-23" = {
          name = "Qwen3 Max 2026-01-23";
        };
        "qwen3-coder-next" = {
          name = "Qwen3 Coder Next";
        };
        "qwen3-coder-plus" = {
          name = "Qwen3 Coder Plus";
        };
        "MiniMax-M2.5" = {
          name = "MiniMax M2.5";
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 1024;
            };
          };
        };
        "glm-5" = {
          name = "GLM-5";
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 1024;
            };
          };
        };
        "glm-4.7" = {
          name = "GLM-4.7";
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 1024;
            };
          };
        };
        "kimi-k2.5" = {
          name = "Kimi K2.5";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [
              "text"
            ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 1024;
            };
          };
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
