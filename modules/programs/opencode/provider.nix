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

    google = {
      models = {
        "antigravity-gemini-3-pro-low" = {
          name = "Gemini 3 Pro Low (Antigravity)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-gemini-3-pro-high" = {
          name = "Gemini 3 Pro High (Antigravity)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-gemini-3-flash" = {
          name = "Gemini 3 Flash (Antigravity)";
          limit = { context = 1048576; output = 65536; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "gemini-3-pro-low" = {
          name = "Gemini 3 Pro Low (Gemini)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "gemini-3-pro-high" = {
          name = "Gemini 3 Pro High (Gemini)";
          limit = { context = 1048576; output = 65535; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "gemini-3-flash" = {
          name = "Gemini 3 Flash (Gemini)";
          limit = { context = 1048576; output = 65536; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5" = {
          name = "Claude Sonnet 4.5 (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5-thinking-low" = {
          name = "Claude Sonnet 4.5 Low (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5-thinking-medium" = {
          name = "Claude Sonnet 4.5 Medium (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-sonnet-4-5-thinking-high" = {
          name = "Claude Sonnet 4.5 High (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-opus-4-5-thinking-low" = {
          name = "Claude Opus 4.5 Low (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-opus-4-5-thinking-medium" = {
          name = "Claude Opus 4.5 Medium (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
        "antigravity-claude-opus-4-5-thinking-high" = {
          name = "Claude Opus 4.5 High (Antigravity)";
          limit = { context = 200000; output = 64000; };
          modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
        };
      };
    };
  };
}
