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
      "ninerouter" = {
        npm = "@ai-sdk/openai-compatible";
        id = "ninerouter";
        name = "ninerouter";
        options = {
          baseURL = "https://router9.josevictor.me/v1";
          apiKey = "{env:NINEROUTER_API_KEY}";
        };
        models = {
          "mimo-v2.5-pro" = {
            name = "Mimo V2.5 Pro (ninerouter)";
          };
          "mimo-v2.5" = {
            name = "Mimo V2.5 (ninerouter)";
          };
          "gpt-5.5" = {
            name = "GPT 5.5";
          };
          "kimi-k2.5" = {
            name = "Kimi K2.5 (ninerouter)";
          };
          "kimi-k2.6" = {
            name = "Kimi K2.6 (ninerouter)";
          };
          "deepseek-v4-flash" = {
            name = "DeepSeek V4 Flash (ninerouter)";
          };
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro (ninerouter)";
          };
          "glm-5.1" = {
            name = "GLM-5.1 (ninerouter)";
          };
          "glm-5" = {
            name = "GLM-5 (ninerouter)";
          };
          "glm-4.7" = {
            name = "GLM-4.7 (ninerouter)";
          };
          "minimax-m2.7" = {
            name = "MiniMax M2.7 (ninerouter)";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5 (ninerouter)";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus (ninerouter)";
          };
          "samwise" = {
            name = "Samwise (ninerouter)";
          };
          "pippin" = {
            name = "Pippin (ninerouter)";
          };
          "haldir" = {
            name = "Haldir (ninerouter)";
          };
        };
      };
    };
  };
}
