# config/provider.nix - AI provider configurations for OpenCode
_: {
  config.jvf.programs.opencode.settings.provider = {
    local = {
      npm = "@ai-sdk/openai-compatible";
      name = "Local";
      options = {
        baseURL = "http://10.10.10.10:8080/v1";
      };
      models = {
        "0n9ljpgzn31y0bvcq6pbwvgmx2lz9kvr-gemma-4-26B-A4B-it-UD-Q3_K_M.gguf" = {
          name = "Gemma 4 26B A4B IT UD Q3_K_M (Local)";
        };
        "ygxn6zpv0yd2z2p07zyvk9jk7rk9s6nr-Qwopus-GLM-18B-Healed-Q3_K_M.gguf" = {
          name = "Qwopus GLM 18B Healed Q3_K_M (Local)";
        };
      };
    };

    inception = {
      npm = "@ai-sdk/openai-compatible";
      name = "Inception";
      options = {
        baseURL = "https://api.inceptionlabs.ai/v1/";
        apiKey = "{env:INCEPTION_API_KEY}";
      };
      models = {
        "mercury-2" = {
          name = "Mercury 2 (Inception)";
          max_tokens = 16384;
        };
      };
    };

    openrouter = {
      npm = "@ai-sdk/openai-compatible";
      name = "OpenRouter";
      options = {
        baseURL = "https://openrouter.ai/api/v1";
        apiKey = "{env:OPENROUTER_API_KEY_CODE_AGENT}";
      };
    };

    alibaba-coding-plan = {
      npm = "@ai-sdk/anthropic";
      name = "Alibaba Coding Plan";
      options = {
        baseURL = "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic/v1";
        apiKey = "{env:ALIBABA_CODING_PLAN_API_KEY}";
      };
      models = {
        "qwen3.5-plus" = {
          name = "Qwen3.5 Plus";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 1000000;
            output = 65536;
          };
        };
        "qwen3.6-plus" = {
          name = "Qwen3.6 Plus";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 1000000;
            output = 65536;
          };
        };
        "qwen3-max-2026-01-23" = {
          name = "Qwen3 Max 2026-01-23";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          limit = {
            context = 262144;
            output = 32768;
          };
        };
        "qwen3-coder-next" = {
          name = "Qwen3 Coder Next";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          limit = {
            context = 262144;
            output = 65536;
          };
        };
        "qwen3-coder-plus" = {
          name = "Qwen3 Coder Plus";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          limit = {
            context = 1000000;
            output = 65536;
          };
        };
        "MiniMax-M2.5" = {
          name = "MiniMax M2.5";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 196608;
            output = 24576;
          };
        };
        "glm-5" = {
          name = "GLM-5";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 202752;
            output = 16384;
          };
        };
        "glm-4.7" = {
          name = "GLM-4.7";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 202752;
            output = 16384;
          };
        };
        "kimi-k2.5" = {
          name = "Kimi K2.5";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 262144;
            output = 32768;
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

    kimi-for-coding = {
      npm = "@ai-sdk/anthropic";
      name = "Kimi For Coding";
      options = {
        baseURL = "https://api.kimi.com/coding/v1";
        apiKey = "{env:KIMI_API_KEY}";
      };
      models = {
        "kimi-k2.6" = {
          name = "Kimi K2.6";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 262144;
            output = 32768;
          };
        };
        "kimi-k2.5" = {
          name = "Kimi K2.5";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          limit = {
            context = 262144;
            output = 32768;
          };
        };
      };
    };

    zai-coding-plan = {
      npm = "@ai-sdk/openai-compatible";
      options = {
        baseURL = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "{env:Z_AI_API_KEY}";
      };
      models = {
        "glm-5-turbo" = {
          name = "GLM-5 Turbo";
        };
        "glm-5.1" = {
          name = "GLM-5.1";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          variants = {
            thinker = {
              name = "GLM-5.1 Deep Thinker";
              reasoningEffort = "high";
              thinking = {
                type = "enabled";
              };
              temperature = 1.0;
            };
            fast = {
              name = "GLM-5.1 Fast";
              reasoningEffort = "low";
              textVerbosity = "low";
              thinking.type = "disabled";
              temperature = 0.1;
              clear_thinking = false;
            };
          };
          limit = {
            context = 202752;
            output = 16384;
          };
        };
        "glm-5" = {
          name = "GLM-5";
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 8192;
            };
          };
          variants = {
            thinker = {
              name = "GLM-5 Deep Thinker";
              reasoningEffort = "high";
              thinking = {
                type = "enabled";
              };
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
          limit = {
            context = 202752;
            output = 16384;
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
