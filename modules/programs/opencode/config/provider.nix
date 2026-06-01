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
        npm = "@ai-sdk/anthropic";
        id = "omniroute";
        name = "omniroute";
        options = {
          baseURL = "https://omniroute.josevictor.me/v1";
          apiKey = "{env:OMNIROUTE_API_KEY}";
          headers = {
            "anthropic-version" = "2023-06-01";
          };
        };
        models = {
          "mimo-v2.5-pro" = {
            name = "Mimo V2.5 Pro (omniroute)";
          };
          "mimo-v2.5" = {
            name = "Mimo V2.5 (omniroute)";
          };
          "gpt-5.5" = {
            name = "GPT 5.5";
          };
          "kimi-k2.5" = {
            name = "Kimi K2.5 (omniroute)";
          };
          "kimi-k2.6" = {
            name = "Kimi K2.6 (omniroute)";
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
          "kimi-k2.6-thinking" = {
            name = "Kimi K2.6 Thinking (omniroute)";
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
            name = "DeepSeek V4 Flash (omniroute)";
          };
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro (omniroute)";
          };
          "glm-5.1" = {
            name = "GLM-5.1 (omniroute)";
          };
          "glm-5.1-thinking" = {
            name = "GLM-5.1 Thinking (omniroute)";
          };
          "glm-5" = {
            name = "GLM-5 (omniroute)";
          };
          "glm-4.7" = {
            name = "GLM-4.7 (omniroute)";
          };
          "minimax-m2.7" = {
            name = "MiniMax M2.7 (omniroute)";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5 (omniroute)";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus (omniroute)";
          };
          "gandalf" = {
            name = "Gandalf (omniroute)";
          };
          "legolas" = {
            name = "Legolas (omniroute)";
          };
          "pippin" = {
            name = "Pippin (omniroute)";
          };
          "haldir" = {
            name = "Haldir (omniroute)";
          };
        };
      };
    };
  };
}
