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
        "apriel-nemotron-15b-thinker" = {
          name = "Apriel Nemotron 15b Thinker";
        };
        "qwen3-coder-30b-a3b-instruct" = {
          name = "Qwen3 Coder 30b a3b Instruct";
        };
        "openai/gpt-oss-20b" = {
          name = "GPT OSS 20b";
          options = {
            reasoningEffort = "high";
            textVerbosity = "low";
            reasoningSummary = "auto";
          };
        };
      };
    };

    minimax = {
      npm = "@ai-sdk/vercel-minimax-ai-provider";
      name = "Minimax";
      options = {
        baseURL = "https://api.minimax.io/anthropic";
        apiKey = "{env:MINIMAX_API_KEY}";
      };
      models = {
        "MiniMax-M2" = {
          name = "Minimax M2";
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
