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

    openrouter = {
      models = {
        "z-ai/glm-4.6:exacto" = {
          name = "GLM 4.6 Exacto";
        };
        "x-ai/grok-4-fast" = {
          name = "Grok 4 Fast";
        };
        "minimax/minimax-m2" = {
          name = "Minimax M2";
        };
        "moonshotai/kimi-k2-0905:exacto" = {
          name = "Kimi K2 Instruct 0905 Exacto";
        };
        "openai/gpt-oss-120b:exacto" = {
          name = "GPT OSS 120b Exacto";
        };
        "deepseek/deepseek-v3.1-terminus:exacto" = {
          name = "DeepSeek v3.1 Exacto";
        };
        "qwen/qwen3-coder:exacto" = {
          name = "Qwen3 Coder Exacto";
        };
        "google/gemini-2.5-pro" = {
          name = "Gemini 2.5 Pro";
        };
        "deepseek/deepseek-v3.2-exp" = {
          name = "DeepSeek: DeepSeek V3.2 Exp";
        };
        "moonshotai/kimi-k2-thinking" = {
          name = "Kimi K2 Thinking";
        };
      };
    };
  };
}
