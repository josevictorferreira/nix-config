{ lib
, pkgs
, config
, username
, ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.claudecode;

  ccrHost = "127.0.0.1";
  ccrPort = 3456;
  routerApiKey = "local-dev";

  ccrPkg = pkgs.writeShellScriptBin "ccr" ''
    ${pkgs.bun}/bin/bunx @musistudio/claude-code-router "$@"
  '';

  configPath = json.generate "ccr-config.json" cfg.settings;

  sanitize = name: lib.replaceStrings [ "/" " " ] [ "_" "-" ] name;

  aiTools = import ../common/ai-tools { inherit lib pkgs; };
  agentEntries = lib.mapAttrsToList
    (name: text: {
      rel = "agents/${sanitize name}.md";
      src = pkgs.writeText "agent-${sanitize name}.md" text;
    })
    aiTools.agents;
  commandEntries = lib.mapAttrsToList
    (name: text: {
      rel = "commands/${sanitize name}.md";
      src = pkgs.writeText "command-${sanitize name}.md" text;
    })
    aiTools.commands;
  installAgents = lib.concatStringsSep "\n" (
    map
      (e: ''
        install -m 0644 -D ${e.src} "$dest/${e.rel}"
      '')
      agentEntries
  );
  installCommands = lib.concatStringsSep "\n" (
    map
      (e: ''
        install -m 0644 -D ${e.src} "$dest/${e.rel}"
      '')
      commandEntries
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
      pkgs.claude-code
      pkgs.bun
      ccrPkg
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
