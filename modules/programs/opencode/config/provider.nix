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
          "kimi-k2.6" = {
            name = "Kimi K2.6 (OmniRoute)";
            limit = {
              context = 262144;
              output = 32768;
            };
            reasoning = true;
            options = {
              temperature = 1.0;
              top_p = 0.95;
            };
            cost = {
              input = 0.95;
              output = 4.0;
              cache_read = 0.16;
            };
            modalities = {
              output = [ "text" ];
            };
          };
          "kimi-k2.6-thinking" = {
            name = "Kimi K2.6 Thinking (OmniRoute)";
            limit = {
              context = 262144;
              output = 32768;
            };
            reasoning = true;
            options = {
              temperature = 1.0;
              top_p = 0.95;
            };
            cost = {
              input = 0.95;
              output = 4.0;
              cache_read = 0.16;
            };
            modalities = {
              output = [ "text" ];
            };
          };
          "deepseek-v4-flash" = {
            name = "DeepSeek V4 Flash (OmniRoute)";
          };
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro (OmniRoute)";
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
          "minimax-m2.7" = {
            name = "MiniMax M2.7 (OmniRoute)";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5 (OmniRoute)";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus (OmniRoute)";
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
          "legolas" = {
            name = "Legolas (OmniRoute)";
          };
          "pippin" = {
            name = "Pippin (OmniRoute)";
          };
          "haldir" = {
            name = "Haldir (OmniRoute)";
          };
        };
      };
    };
  };
}
