{
  pkgs,
  ...
}:

let
  ccrHost = "127.0.0.1";
  ccrPort = 3456;

  routerApiKey = "local-dev";

  ccrConfig = {
    LOG = true;
    HOST = ccrHost;
    PORT = ccrPort;
    API_TIMEOUT_MS = 600000;
    NON_INTERACTIVE_MODE = false;

    APIKEY = routerApiKey;

    Providers = [
      {
        name = "openrouter";
        api_base_url = "https://openrouter.ai/api/v1/chat/completions";
        api_key = "\${OPENROUTER_API_KEY_CODE_AGENT}";

        models = [
          "anthropic/claude-sonnet-4.5"
          "google/gemini-2.5-flash-image"
          "google/gemini-2.5-flash-lite:online"
          "google/gemini-2.5-pro"
          "moonshotai/kimi-k2-0905"
          "moonshotai/kimi-k2"
          "qwen/qwen3-coder-480b"
          "qwen/qwen3-235b-a22b-thinking-2507"
          "x-ai/grok-4-fast"
          "z-ai/glm-4.6"
          "z-ai/glm-4.6:thinking"
        ];

        transformer = {
          use = [ "openrouter" ];
        };
      }
    ];

    Router = {
      default = "openrouter,z-ai/glm-4.6";
      background = "openrouter,z-ai/glm-4.6";
      think = "openrouter,qwen/qwen3-235b-a22b-thinking-2507";
      longContext = "openrouter,google/gemini-2.5-pro";
      webSearch = "openrouter,google/gemini-2.5-flash-lite:online";
      image = "openrouter,google/gemini-2.5-flash-image";
      longContextThreshold = 200000;
    };
  };
in
{
  home.packages = with pkgs; [
    claude-code
    bun
    uv
    pipx
    (pkgs.writeShellScriptBin "ccr" ''
      ${pkgs.bun}/bin/bunx @musistudio/claude-code-router "$@"
    '')
  ];

  home.file.".claude-code-router/config.json".text = builtins.toJSON ccrConfig;

  home.sessionVariables = {
    ANTHROPIC_BASE_URL = "http://${ccrHost}:${toString ccrPort}";
    ANTHROPIC_AUTH_TOKEN = routerApiKey;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
}
