# Aspect: programs-claudecode
# Defines jvf.programs.claudecode options for Claude Code and Claude Code Router.
# Linux: uses FHS environment for glibc compatibility.
# Darwin: direct npm global installation.
{ ... }:
let
  mkClaudecodeOptions =
    { lib, pkgs, ... }:
    let
      json = pkgs.formats.json { };
    in
    {
      options.jvf.programs.claudecode = {
        enable = lib.mkEnableOption "Install claude-code router and write per-user ~/.claude-code-router/config.json";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to install the configuration";
        };
        baseRules = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "A set of base rules to apply to the Claude configuration.";
        };
        agents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Agents to install into the configuration (string prompts or structured objects)";
        };
        commands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Commands to install into the configuration (string prompts or structured objects)";
        };
        mcps = lib.mkOption {
          type = lib.types.attrsOf json.type;
          default = { };
          description = "MCP tools to install into the configuration (structured objects)";
        };
        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Skills to install into the configuration";
        };
        settings = lib.mkOption {
          type = json.type;
          default = { };
          description = "ClaudeCode settings.";
        };
        routerSettings = lib.mkOption {
          type = json.type;
          default = {
            LOG = true;
            HOST = "127.0.0.1";
            PORT = 3456;
            API_TIMEOUT_MS = 600000;
            NON_INTERACTIVE_MODE = false;
            APIKEY = "local-dev";
            Providers = [
              {
                name = "openrouter";
                api_base_url = "https://openrouter.ai/api/v1/chat/completions";
                api_key = "\${OPENROUTER_API_KEY_CODE_AGENT}";
                models = [
                  "anthropic/claude-sonnet-4.5"
                  "anthropic/claude-haiku-4.5"
                  "google/gemini-2.5-flash-image"
                  "google/gemini-2.5-flash-lite:online"
                  "google/gemini-2.5-pro"
                  "moonshotai/kimi-k2-0905"
                  "moonshotai/kimi-k2-0905:exacto"
                  "moonshotai/kimi-k2"
                  "qwen/qwen3-coder-480b"
                  "qwen/qwen3-235b-a22b-2507"
                  "x-ai/grok-4-fast"
                  "x-ai/grok-code-fast-1"
                  "x-ai/grok-4"
                  "z-ai/glm-4.6"
                  "z-ai/glm-4.6:exacto"
                  "minimax/minimax-m2:free"
                  "openai/gpt-oss-120b:exacto"
                  "deepseek/deepseek-v3.1-terminus:exacto"
                  "deepseek/deepseek-v3.2-exp"
                  "moonshotai/kimi-k2-thinking"
                  "google/gemini-3-pro-preview"
                  "z-ai/glm-4.7"
                ];
                transformer = {
                  use = [ "openrouter" ];
                };
              }
            ];
            Router = {
              default = "openrouter,z-ai/glm-4.7";
              background = "openrouter,openai/gpt-oss-120b:exacto";
              think = "openrouter,moonshotai/kimi-k2-thinking";
              longContext = "openrouter,z-ai/glm-4.7";
              webSearch = "openrouter,google/gemini-2.5-flash-lite:online";
              image = "openrouter,google/gemini-2.5-flash-image";
              longContextThreshold = 250000;
            };
            StatusLine = {
              enabled = true;
              currentStyle = "powerline";
              default = {
                modules = [ ];
              };
              powerline = {
                modules = [
                  {
                    type = "model";
                    icon = "🤖";
                    text = "{{model}}";
                    color = "bright_yellow";
                  }
                  {
                    type = "usage";
                    icon = "📊";
                    text = "{{inputTokens}} → {{outputTokens}}";
                    color = "bright_magenta";
                  }
                  {
                    type = "workDir";
                    icon = "󰉋";
                    text = "{{workDirName}}";
                    color = "bright_blue";
                  }
                  {
                    type = "gitBranch";
                    icon = "🌿";
                    text = "{{gitBranch}}";
                    color = "bright_green";
                  }
                  {
                    type = "speed";
                    icon = "⚡";
                    text = "{{tokenSpeed}}";
                    color = "bright_green";
                  }
                  {
                    type = "script";
                    icon = "📜";
                    text = "Script Module";
                    color = "bright_cyan";
                    scriptPath = "";
                  }
                ];
              };
            };
          };
          description = "Settings written to ~/.claude-code-router/config.json";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.jvf.programs.claudecode;
      json = pkgs.formats.json { };

      # FHS environment for Linux (claude-code needs glibc, etc.)
      claudeCodeFHS =
        if (!isDarwin) then
          pkgs.buildFHSEnv {
            name = "claude-fhs";
            targetPkgs =
              pkgs: with pkgs; [
                stdenv.cc.cc.lib
                zlib
                openssl
                curl
                nodejs_22
                coreutils
              ];
            profile = ''
              export TMPDIR="''${TMPDIR:-$HOME/.cache/claude-tmp}"
              mkdir -p "$TMPDIR"
            '';
            runScript = "${pkgs.writeShellScript "claude-runner" ''
              exec "$HOME/.npm-global/bin/claude" "$@"
            ''}";
          }
        else
          null;

      claudeRouterFHS =
        if (!isDarwin) then
          pkgs.buildFHSEnv {
            name = "claude-router-fhs";
            targetPkgs =
              pkgs: with pkgs; [
                stdenv.cc.cc.lib
                zlib
                openssl
                curl
                nodejs_22
                coreutils
              ];
            profile = ''
              export TMPDIR="''${TMPDIR:-$HOME/.cache/claude-tmp}"
              mkdir -p "$TMPDIR"
            '';
            runScript = "${pkgs.writeShellScript "claude-router-runner" ''
              exec "$HOME/.npm-global/bin/ccr" "$@"
            ''}";
          }
        else
          null;

      # Wrapper script for claude-code
      claudeCodeBin = pkgs.writeShellScriptBin "claude" ''
        set -euo pipefail

        # Suppress Node.js deprecation warnings
        export NODE_NO_WARNINGS=1

        NPM_GLOBAL_DIR="$HOME/.npm-global"
        NPM_GLOBAL_BIN="$NPM_GLOBAL_DIR/bin"
        CLAUDE_BIN="$NPM_GLOBAL_BIN/claude"

        # Ensure npm global directory exists and is configured
        mkdir -p "$NPM_GLOBAL_DIR"
        ${pkgs.nodejs_22}/bin/npm config set prefix "$NPM_GLOBAL_DIR" 2>/dev/null || true

        # Install claude-code if not present
        if [ ! -x "$CLAUDE_BIN" ]; then
          echo "Installing claude-code..."
          PATH="$NPM_GLOBAL_BIN:$PATH" ${pkgs.nodejs_22}/bin/npm install -g @anthropic-ai/claude-code
        fi

        ${
          if (!isDarwin) then
            ''
              exec "${claudeCodeFHS}/bin/claude-fhs" "$@"
            ''
          else
            ''
              exec "$CLAUDE_BIN" "$@"
            ''
        }
      '';

      # Wrapper script for claude-code-router (binary is named 'ccr')
      claudeRouterBin = pkgs.writeShellScriptBin "ccr" ''
        set -euo pipefail

        # Suppress Node.js deprecation warnings
        export NODE_NO_WARNINGS=1

        NPM_GLOBAL_DIR="$HOME/.npm-global"
        NPM_GLOBAL_BIN="$NPM_GLOBAL_DIR/bin"
        ROUTER_BIN="$NPM_GLOBAL_BIN/ccr"

        # Ensure npm global directory exists and is configured
        mkdir -p "$NPM_GLOBAL_DIR"
        ${pkgs.nodejs_22}/bin/npm config set prefix "$NPM_GLOBAL_DIR" 2>/dev/null || true

        # Install claude-code-router if not present
        if [ ! -x "$ROUTER_BIN" ]; then
          echo "Installing claude-code-router..."
          PATH="$NPM_GLOBAL_BIN:$PATH" ${pkgs.nodejs_22}/bin/npm install -g @musistudio/claude-code-router
        fi

        ${
          if (!isDarwin) then
            ''
              exec "${claudeRouterFHS}/bin/claude-router-fhs" "$@"
            ''
          else
            ''
              exec "$ROUTER_BIN" "$@"
            ''
        }
      '';
    in
    {
      imports = [ mkClaudecodeOptions ];

      config = lib.mkIf cfg.enable (
        {
          jvf.wrappers.users.${cfg.username}.programs = {
            claude = {
              preserveFiles = [
                "transcripts"
                "cache"
                "debug"
                "projects"
                "shell-snapshots"
                "todos"
                "history.jsonl"
              ];
              packages = [
                claudeCodeBin
              ];
              configPath = ".claude";
              configs = lib.mkMerge [
                (inputs.lib.aiTools.mkClaudecodeMdConfigs config.jvf.aiTools.mcp "agents" cfg.agents)
                (inputs.lib.aiTools.mkClaudecodeMdConfigs config.jvf.aiTools.mcp "commands" cfg.commands)
                (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
              ];
            };
            claude-code-router = {
              preserveFiles = [
                "logs"
                "plugins"
                ".claude-code-router.pid"
              ];
              packages = [
                claudeRouterBin
              ];
              configPath = ".claude-code-router";
              configs = {
                "config.json" = cfg.routerSettings;
              };
            };
          };
        }
        // lib.optionalAttrs (!isDarwin) {
          environment.etc."claude-code/managed-mcp.json".text = builtins.toJSON {
            mcpServers = cfg.mcps;
          };
        }
        // lib.optionalAttrs isDarwin {
          system.activationScripts.claudeCodeMcp.text = ''
            targetDir="/Library/Application Support/ClaudeCode"
            targetFile="$targetDir/managed-mcp.json"

            # Define the content in the Nix store (immutable)
            sourceFile="${pkgs.writeText "managed-mcp.json" (builtins.toJSON { mcpServers = cfg.mcps; })}"

            echo "Configuring Claude Code Managed MCP..."
            mkdir -p "$targetDir"

            # Symlink the immutable file to the target location
            ln -sf "$sourceFile" "$targetFile"
          '';
        }
      );
    };
in
{
  flake.modules.nixos.programs-claudecode = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-claudecode = mkConfig { isDarwin = true; };
}
