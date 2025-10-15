{ ... }:
{
  config.jvf.programs.opencode.settings.provider = {
    openrouter = {
      models = {
        "z-ai/glm-4.6" = {
          name = "GLM 4.6";
        };
        "x-ai/grok-4-fast" = {
          name = "Grok 4 Fast";
        };
        "moonshotai/kimi-k2-0905" = {
          name = "Kimi K2 Instruct 0905";
        };
        "google/gemini-2.5-pro" = {
          name = "Gemini 2.5 Pro";
        };
      };
    };
  };
}
