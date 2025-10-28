{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.claudecode;

  ccrHost = "127.0.0.1";
  ccrPort = 3456;
  routerApiKey = "local-dev";

  claudeCodePkg = pkgs.writeShellScriptBin "claude" ''
    INSTALL_URL="-fsSL https://claude.ai/install.sh"
    LOCAL_BIN="$HOME/.local/bin"
    LOCAL_CLAUDE="$LOCAL_BIN/claude"
    CLAUDE_BIN_DIR="$HOME/.claude/bin"

    if [ ! -x "$LOCAL_DROID" ]; then
      mkdir -p "$LOCAL_BIN"
      PATH="$CLAUDE_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
    fi

    exec "$LOCAL_BIN/claude" "$@"
  '';

  claudeCodeRouterPkg = pkgs.writeShellScriptBin "ccr" ''
    ${pkgs.bun}/bin/bunx @musistudio/claude-code-router "$@"
  '';

  configPath = json.generate "ccr-config.json" cfg.settings;

  sanitize = name: lib.replaceStrings [ "/" " " ] [ "_" "-" ] name;

  aiTools = import ../common/ai-tools { inherit lib pkgs; };
  agentEntries = lib.mapAttrsToList (name: text: {
    rel = "agents/${sanitize name}.md";
    src = pkgs.writeText "agent-${sanitize name}.md" text;
  }) aiTools.agents;
  commandEntries = lib.mapAttrsToList (name: text: {
    rel = "commands/${sanitize name}.md";
    src = pkgs.writeText "command-${sanitize name}.md" text;
  }) aiTools.commands;
  installAgents = lib.concatStringsSep "\n" (
    map (e: ''
      install -m 0644 -D ${e.src} "$dest/${e.rel}"
    '') agentEntries
  );
  installCommands = lib.concatStringsSep "\n" (
    map (e: ''
      install -m 0644 -D ${e.src} "$dest/${e.rel}"
    '') commandEntries
  );
in
{
  options.jvf.programs.claudecode = {
    enable = lib.mkEnableOption "Install claude-code router and write per-user ~/.claude-code-router/config.json";

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.claude-code-router/config.json";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bun
      pkgs.nodejs_20
      pkgs.patchelf
      claudeCodePkg
      claudeCodeRouterPkg
    ];

    jvf.programs.claudecode.settings = lib.mkDefault {
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
            # In, Out
            "anthropic/claude-sonnet-4.5" # $3, $15
            "anthropic/claude-haiku-4.5" # $1, $5
            "google/gemini-2.5-flash-image" # $0.3, $2.5
            "google/gemini-2.5-flash-lite:online" # $0.1, $0.4
            "google/gemini-2.5-pro" # $1.25, $10
            "moonshotai/kimi-k2-0905" # $0.39, $1.90
            "moonshotai/kimi-k2-0905:exacto" # $0.60, $2.50
            "moonshotai/kimi-k2" # $0.14, $2.49
            "qwen/qwen3-coder-480b" # $0.22, $0.95
            "qwen/qwen3-235b-a22b-2507" # $0.08, $0.55
            "x-ai/grok-4-fast" # $0.20, $0.50
            "x-ai/grok-code-fast-1" # $0.20, $1.50
            "x-ai/grok-4" # $3, $15
            "z-ai/glm-4.6" # $0.40, $1.75
            "z-ai/glm-4.6:exacto" # $0.60, $1.90
            "minimax/minimax-m2:free" # $0, $0
            "openai/gpt-oss-120b:exacto" # $0.04, $0.40
            "deepseek/deepseek-v3.1-terminus:exacto" # $0.27, $1
            "deepseek/deepseek-v3.2-exp" # 0.27, $0.40
          ];
          transformer = {
            use = [ "openrouter" ];
          };
        }
      ];
      Router = {
        default = "openrouter,moonshotai/kimi-k2-0905";
        background = "openrouter,openai/gpt-oss-120b:exacto";
        think = "openrouter,qwen/qwen3-235b-a22b-thinking-2507";
        longContext = "openrouter,x-ai/grok-4-fast";
        webSearch = "openrouter,google/gemini-2.5-flash-lite:online";
        image = "openrouter,google/gemini-2.5-flash-image";
        longContextThreshold = 250000;
      };
    };

    system.activationScripts.ccr = lib.stringAfter [ "users" ] ''
      set -euo pipefail
      user="${username}"
      home="$(getent passwd "$user" | cut -d: -f6 || true)"
      if [ -n "$home" ] && [ -d "$home" ]; then
        dest="$home/.claude-code-router"

        group="$(id -gn "$user" 2>/dev/null || echo users)"
        install -d -m 0755 -o "$user" -g "$group" "$dest"
        install -m 0644 -o "$user" -g "$group" -D ${configPath} "$dest/config.json"
      else
        echo "ccr: user '$user' not found or has no home directory" >&2
      fi
    '';

    system.activationScripts.claudecode = lib.stringAfter [ "users" ] ''
      set -euo pipefail
      user="${username}"
      home="$(getent passwd "$user" | cut -d: -f6 || true)"
      if [ -n "$home" ] && [ -d "$home" ]; then
        dest="$home/.claude"

        group="$(id -gn "$user" 2>/dev/null || echo users)"

        mkdir -p "$dest" "$dest/agents" "$dest/commands"

        # agents
        ${installAgents}

        # commands
        ${installCommands}

        chown -R "$user":"$group" "$dest"
      else
        echo "opencode: user '$user' not found or has no home directory" >&2
      fi
    '';
  };
}
