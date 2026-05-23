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
      "9-router" = {
        npm = "@ai-sdk/openai-compatible";
        name = "9Router";
        options = {
          baseURL = "https://router9.josevictor.me/v1";
          apiKey = "{env:NINEROUTER_API_KEY}";
        };
        models = {
          "gpt-5.5" = {
            name = "GPT 5.5";
          };
          "kimi-k2.5" = {
            name = "Kimi K2.5 (9Router)";
          };
          "kimi-k2.6" = {
            name = "Kimi K2.6 (9Router)";
          };
          "deepseek-v4-flash" = {
            name = "DeepSeek V4 Flash (9Router)";
          };
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro (9Router)";
          };
          "glm-5.1" = {
            name = "GLM-5.1 (9Router)";
          };
          "glm-5" = {
            name = "GLM-5 (9Router)";
          };
          "glm-4.7" = {
            name = "GLM-4.7 (9Router)";
          };
          "minimax-m2.7" = {
            name = "MiniMax M2.7 (9Router)";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5 (9Router)";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus (9Router)";
          };
          "cheap-nitro" = {
            name = "Cheap Nitro (9Router)";
          };
          "cheap-fast" = {
            name = "Cheap Fast (9Router)";
          };
        };
      };
    };
  };
}
