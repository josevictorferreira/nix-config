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

    openrouter = {
      models = {
        "z-ai/glm-4.6:exacto" = {
          name = "GLM 4.6 Exacto";
        };
        "x-ai/grok-4.1-fast" = {
          name = "Grok 4.1 Fast";
        };
        "minimax/minimax-m2" = {
          name = "Minimax M2";
          options = {
            provider = {
              only = [
                "minimax/fp8"
              ];
            };
          };
        };
        "moonshotai/kimi-k2-0905:exacto" = {
          name = "Kimi K2 Instruct 0905 Exacto";
        };
        "openai/gpt-oss-120b:exacto" = {
          name = "GPT OSS 120b Exacto";
        };
        "moonshotai/kimi-k2-thinking" = {
          name = "Kimi K2 Thinking";
          options = {
            provider = {
              only = [
                "moonshotai/int4"
                "moonshotai/turbo"
              ];
            };
          };
        };
        "google/gemini-3-pro-preview" = {
          name = "Gemini 3 Pro Preview - Openrouter";
        };
        "openai/gpt-5.1-codex-max" = {
          name = "GPT 5.1 Codex Max - Openrouter";
        };
      };
    };
  };
}
