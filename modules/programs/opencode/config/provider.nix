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
      "omniroute" = {
        npm = "@ai-sdk/openai-compatible";
        id = "omniroute";
        name = "OmniRoute";
        options = {
          baseURL = "https://omniroute.josevictor.me/v1";
          apiKey = "{env:OMNIROUTE_API_KEY}";
        };
        models = {
          "mimo-v2.5-pro" = {
            name = "Mimo V2.5 Pro (OmniRoute)";
          };
          "mimo-v2.5" = {
            name = "Mimo V2.5 (OmniRoute)";
          };
          "gpt-5.5" = {
            name = "GPT 5.5";
          };
          "kimi-k2.5" = {
            name = "Kimi K2.5 (OmniRoute)";
          };
          "kimi-k2.7-code" = {
            name = "Kimi K2.7 Code (OmniRoute)";
          };
          "kimi-k3" = {
            name = "Kimi K3 (OmniRoute)";
          };
          "kimi-coding" = {
            name = "Kimi Coding (OmniRoute)";
          };
          "kimi-highspeed" = {
            name = "Kimi Highspeed (OmniRoute)";
          };
          "kimi-k2.6" = {
            name = "Kimi K2.6 (OmniRoute)";
          };
          "kimi-k2.6-thinking" = {
            name = "Kimi K2.6 Thinking (OmniRoute)";
          };
          "deepseek-v4-flash" = {
            name = "DeepSeek V4 Flash (OmniRoute)";
          };
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro (OmniRoute)";
          };
          "glm-5.2" = {
            name = "GLM-5.2 (OmniRoute)";
          };
          "glm-5.2-max" = {
            name = "GLM-5.2 Max (OmniRoute)";
          };
          "glm-5.1" = {
            name = "GLM-5.1 (OmniRoute)";
          };
          "glm-5.1-thinking" = {
            name = "GLM-5.1 Thinking (OmniRoute)";
          };
          "glm-5" = {
            name = "GLM-5 (OmniRoute)";
          };
          "glm-4.7" = {
            name = "GLM-4.7 (OmniRoute)";
          };
          "minimax-m3" = {
            name = "MiniMax M3 (OmniRoute)";
          };
          "minimax-m2.7" = {
            name = "MiniMax M2.7 (OmniRoute)";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5 (OmniRoute)";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus (OmniRoute)";
          };
          "qwen3.7-plus" = {
            name = "Qwen 3.7 Plus (OmniRoute)";
          };
          "qwen3.7-max" = {
            name = "Qwen 3.7 Max (OmniRoute)";
          };
          "gandalf" = {
            name = "Gandalf (OmniRoute)";
          };
          "radagast" = {
            name = "Radagast (OmniRoute)";
          };
          "saruman" = {
            name = "Saruman (OmniRoute)";
          };
          "sauron" = {
            name = "Sauron (OmniRoute)";
          };
          "legolas" = {
            name = "Legolas (OmniRoute)";
          };
          "pippin" = {
            name = "Pippin (OmniRoute)";
          };
          "haldir" = {
            name = "Haldir (OmniRoute)";
          };
          "samwise" = {
            name = "Samwise (OmniRoute)";
          };
        };
      };
    };
  };
}
