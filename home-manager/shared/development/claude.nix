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
        api_key = "$OPENROUTER_API_KEY";

        models = [
          "moonshotai/kimi-k2-0905"
          "z-ai/glm-4.6"
          "qwen/qwen3-coder-480b"
        ];

        transformer = {
          use = [ "openrouter" ];
        };
      }
    ];

    Router = {
      default = "openrouter,moonshotai/kimi-k2-0905";
      background = "openrouter,moonshotai/kimi-k2-0905";
      think = "qwen/qwen3-235b-a22b-thinking-2507";
      longContext = "openrouter,moonshotai/kimi-k2-0905";
      longContextThreshold = 60000;
    };
  };
in
{
  home.packages = with pkgs; [
    claude-code
    bun
  ];

  home.file.".claude-code-router/config.json".text = builtins.toJSON ccrConfig;

  home.shellAliases = {
    ccr = "${pkgs.bun}/bin/bunx @musistudio/claude-code-router";
  };

  home.sessionVariables = {
    ANTHROPIC_BASE_URL = "http://${ccrHost}:${toString ccrPort}";
    ANTHROPIC_AUTH_TOKEN = routerApiKey;
  };
}
