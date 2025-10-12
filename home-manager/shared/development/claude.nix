{
  lib,
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
          "z-ai/glm-4.6"
          "z-ai/glm-4.6:thinking"
          "google/gemini-2.5-pro:online"
          "google/gemini-2.5-flash-image"
          "moonshotai/kimi-k2-0905"
          "qwen/qwen3-coder-480b"
        ];

        transformer = {
          use = [ "openrouter" ];
        };
      }
    ];

    Router = {
      default = "openrouter,z-ai/glm-4.6";
      background = "openrouter,moonshotai/kimi-k2-0905";
      think = "openrouter,z-ai/glm-4.6:thinking";
      longContext = "openrouter,z-ai/glm-4.6";
      webSearch = "openrouter,google/gemini-2.5-pro:online";
      image = "openrouter,google/gemini-2.5-flash-image";
      longContextThreshold = 200000;
    };
  };
in
{
  home.packages = with pkgs; [
    claude-code
    bun
    pipx
    (pkgs.writeShellScriptBin "SuperClaude" ''
      exec "$HOME/.local/bin/SuperClaude" "$@"
    '')
    (pkgs.writeShellScriptBin "superclaude" ''
      exec "$HOME/.local/bin/superclaude" "$@"
    '')
    (pkgs.writeShellScriptBin "ccr" ''
      ${pkgs.bun}/bin/bunx @musistudio/claude-code-router "$@"
    '')
  ];

  home.file.".claude-code-router/config.json".text = builtins.toJSON ccrConfig;

  home.sessionVariables = {
    ANTHROPIC_BASE_URL = "http://${ccrHost}:${toString ccrPort}";
    ANTHROPIC_AUTH_TOKEN = routerApiKey;
  };

  home.activation.installSuperClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    export PIPX_HOME="$HOME/.local/share/pipx"
    export PIPX_BIN_DIR="$HOME/.local/bin"
    mkdir -p "$PIPX_HOME" "$PIPX_BIN_DIR"

    ${pkgs.pipx}/bin/pipx install --include-deps SuperClaude
    ${pkgs.pipx}/bin/pipx upgrade SuperClaude

    "$PIPX_BIN_DIR/SuperClaude" install || true
  '';

  home.sessionPath = [ "$HOME/.local/bin" ];
}
