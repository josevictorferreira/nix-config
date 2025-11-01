{ ... }:
{
  config.jvf.programs.opencode.settings.provider = {
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
      };
    };
  };
}
