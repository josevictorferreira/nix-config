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

    "zai" = {
      npm = "@ai-sdk/openai-compatible";
      name = "Z-Ai";
      options = {
        baseURL = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "{env:Z_AI_API_KEY}";
      };
      models = {
        "GLM-4.7" = {
          name = "GLM 4.7";
        };
        "GLM-4.6" = {
          name = "GLM 4.6";
        };
        "GLM-4.6V" = {
          name = "GLM 4.6V";
        };
      };

    };
  };
}
