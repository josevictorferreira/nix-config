# config/provider.nix - AI provider configurations for OpenCode
{ config, ... }:
{
  config.jvf.programs.opencode.settings = {
    disabled_providers = [
      "anthropic"
      "github-copilot"
      "github-models"
      "minimax"
      "google"
      "alibaba-cn"
      "alibaba-coding-plan-cn"
      "zai-coding-plan"
      "kimi-for-coding"
      "openrouter"
      "inception"
      "huggingface"
      "local"
      "alibaba-coding-plan"
      "nvidia"
      "opencode"
      "opencode-go"
    ];
    provider = {
      "9router" = {
        npm = "@ai-sdk/anthropic";
        id = "9router";
        name = "9router";
        options = {
          baseURL = "https://router9.josevictor.me/v1";
          apiKey = "{env:NINEROUTER_API_KEY}";
          headers = {
            "anthropic-version" = "2023-06-01";
          };
        };
        models = {
          "mimo-v2.5-pro" = {
            name = "Mimo V2.5 Pro (9router)";
          };
          "mimo-v2.5" = {
            name = "Mimo V2.5 (9router)";
          };
          "gpt-5.5" = {
            name = "GPT 5.5";
          };
          "kimi-k2.5" = {
            name = "Kimi K2.5 (9router)";
          };
          "kimi-k2.6" = {
            name = "Kimi K2.6 Thinking (9router)";
            limit = {
              context = 262144;
              output = 32768;
            };
            reasoning = true;
            options = {
              temperature = 1.0;
              top_p = 0.95;
              extra_body = {
                thinking = {
                  type = "enabled";
                  keep = "all";
                };
              };
            };
            cost = {
              input = 0.95;
              output = 4.0;
              cache_read = 0.16;
            };
            modalities = {
              input = [
                "text"
                "image"
                "video"
              ];
              output = [ "text" ];
            };
          };
          "deepseek-v4-flash" = {
            name = "DeepSeek V4 Flash (9router)";
          };
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro (9router)";
          };
          "glm-5.1" = {
            name = "GLM-5.1 (9router)";
          };
          "glm-5" = {
            name = "GLM-5 (9router)";
          };
          "glm-4.7" = {
            name = "GLM-4.7 (9router)";
          };
          "minimax-m2.7" = {
            name = "MiniMax M2.7 (9router)";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5 (9router)";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus (9router)";
          };
          "samwise" = {
            name = "Samwise (9router)";
          };
          "pippin" = {
            name = "Pippin (9router)";
          };
          "haldir" = {
            name = "Haldir (9router)";
          };
        };
      };
    };
  };
}
