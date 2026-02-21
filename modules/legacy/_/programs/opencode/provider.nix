{ ... }:
{
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
      # npm = "@ai-sdk/anthropic";
      npm = "@ai-sdk/openai-compatible";
      options = {
        baseURL = "https://api.z.ai/api/coding/paas/v4";
        # baseURL = "https://api.z.ai/api/paas/v4/chat/completions";
        # baseURL = "https://api.z.ai/api/anthropic/v1";
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
                # clear_thinking = false;
                # thinkingBudget = 32768;
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
              thinking.type = "enabled";
              fast.disabled = true;
              max_tokens = 4096;
              temperature = 1.0;
              clear_thinking = false;
            };
            fast = {
              name = "GLM-4.7 Fast";
              reasoningEffort = "low";
              textVerbosity = "low";
              thinking.type = "disabled";
              temperature = 0.4;
              clear_thinking = false;
            };
          };
        };
        "glm-4.7-flash" = {
          name = "GLM-4.7 Flash";
        };
      };
    };

    google = {
      npm = "@ai-sdk/google";
      models = {
        "antigravity-gemini-3.1-pro" = {
          name = "Gemini 3.1 Pro (Antigravity)";
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
          variants = {
            low = {
              thinkingLevel = "low";
            };
            high = {
              thinkingLevel = "high";
            };
          };
        };
        "antigravity-gemini-3-pro" = {
          name = "Gemini 3 Pro (Antigravity)";
          limit = {
            context = 1048576;
            output = 65535;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
          variants = {
            low = {
              thinkingLevel = "low";
            };
            high = {
              thinkingLevel = "high";
            };
          };
        };
        "antigravity-gemini-3-flash" = {
          name = "Gemini 3 Flash (Antigravity)";
          limit = {
            context = 1048576;
            output = 65536;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
          variants = {
            minimal = {
              thinkingLevel = "minimal";
            };
            low = {
              thinkingLevel = "low";
            };
            medium = {
              thinkingLevel = "medium";
            };
            high = {
              thinkingLevel = "high";
            };
          };
        };
        "antigravity-claude-sonnet-4-6" = {
          name = "Claude Sonnet 4.6 (Antigravity)";
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
        "antigravity-claude-sonnet-4-6-thinking" = {
          name = "Claude Sonnet 4.6 Thinking (Antigravity)";
          limit = {
            context = 200000;
            output = 64000;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
          variants = {
            low = {
              thinkingConfig = {
                thinkingBudget = 8192;
              };
            };
            max = {
              thinkingConfig = {
                thinkingBudget = 32768;
              };
            };
          };
        };
        "antigravity-claude-opus-4-5-thinking" = {
          name = "Claude Opus 4.5 Thinking (Antigravity)";
          limit = {
            context = 200000;
            output = 64000;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
          variants = {
            low = {
              thinkingConfig = {
                thinkingBudget = 8192;
              };
            };
            max = {
              thinkingConfig = {
                thinkingBudget = 32768;
              };
            };
          };
        };
        "antigravity-claude-opus-4-6-thinking" = {
          name = "Claude Opus 4.6 Thinking (Antigravity)";
          limit = {
            context = 200000;
            output = 64000;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
          variants = {
            low = {
              thinkingConfig = {
                thinkingBudget = 8192;
              };
            };
            max = {
              thinkingConfig = {
                thinkingBudget = 32768;
              };
            };
          };
        };
        "gemini-2.5-flash" = {
          name = "Gemini 2.5 Flash (Gemini CLI)";
          limit = {
            context = 1048576;
            output = 65536;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
        "gemini-2.5-pro" = {
          name = "Gemini 2.5 Pro (Gemini CLI)";
          limit = {
            context = 1048576;
            output = 65536;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
        "gemini-3-flash-preview" = {
          name = "Gemini 3 Flash Preview (Gemini CLI)";
          limit = {
            context = 1048576;
            output = 65536;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
        "gemini-3.1-pro-preview" = {
          name = "Gemini 3.1 Pro Preview (Gemini CLI)";
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
        "gemini-3-pro-preview" = {
          name = "Gemini 3 Pro Preview (Gemini CLI)";
          limit = {
            context = 1048576;
            output = 65535;
          };
          modalities = {
            input = [
              "text"
              "image"
              "pdf"
            ];
            output = [ "text" ];
          };
        };
      };
    };
  };
}
