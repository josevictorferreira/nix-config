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
      npm = "@ai-sdk/anthropic";
      options = {
        # baseURL = "https://api.z.ai/api/coding/paas/v4";
        baseURL = "https://api.z.ai/api/anthropic/v1";
        apiKey = "{env:Z_AI_API_KEY}";
      };
      models = {
        "glm-5" = {
          name = "GLM-5";
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
        "antigravity-gemini-3-pro-low" = {
          name = "Gemini 3 Pro Low (Antigravity)";
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
        "antigravity-gemini-3-pro-high" = {
          name = "Gemini 3 Pro High (Antigravity)";
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
        };
        "gemini-3-pro-low" = {
          name = "Gemini 3 Pro Low (Gemini)";
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
        "gemini-3-pro-high" = {
          name = "Gemini 3 Pro High (Gemini)";
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
        "gemini-3-flash" = {
          name = "Gemini 3 Flash (Gemini)";
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
        "antigravity-claude-sonnet-4-5" = {
          name = "Claude Sonnet 4.5 (Antigravity)";
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
        };
        "antigravity-claude-sonnet-4-5-thinking-low" = {
          name = "Claude Sonnet 4.5 Low (Antigravity)";
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
        };
        "antigravity-claude-sonnet-4-5-thinking-medium" = {
          name = "Claude Sonnet 4.5 Medium (Antigravity)";
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
        };
        "antigravity-claude-sonnet-4-5-thinking-high" = {
          name = "Claude Sonnet 4.5 High (Antigravity)";
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
        };
        "antigravity-claude-opus-4-5-thinking-low" = {
          name = "Claude Opus 4.5 Low (Antigravity)";
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
        };
        "antigravity-claude-opus-4-5-thinking-medium" = {
          name = "Claude Opus 4.5 Medium (Antigravity)";
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
        };
        "antigravity-claude-opus-4-5-thinking-high" = {
          name = "Claude Opus 4.5 High (Antigravity)";
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
        };
      };
    };
  };
}
