# Aspect: programs-claudecode
# Defines jvf.programs.claudecode options for Claude Code and Claude Code Router.
# Linux: uses FHS environment for glibc compatibility.
# Darwin: direct npm global installation.
_:
let
  # Import default router config as pure data
  defaultRouterConfig = import ./_/router-config.nix { };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.programs.claudecode;

      # FHS environment for Linux (claude-code needs glibc, etc.)
      claudeCodeFHS =
        if (!isDarwin) then
          pkgs.buildFHSEnv
            {
              name = "claude-fhs";
              targetPkgs =
                pkgs: with pkgs; [
                  stdenv.cc.cc.lib
                  zlib
                  openssl
                  curl
                  nodejs_22
                  coreutils
                  tmux
                  fzf
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
          pkgs.buildFHSEnv
            {
              name = "claude-router-fhs";
              targetPkgs =
                pkgs: with pkgs; [
                  stdenv.cc.cc.lib
                  zlib
                  openssl
                  curl
                  nodejs_22
                  coreutils
                  tmux
                  fzf
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
      # Transform raw mcps into Claude Code's expected schema (strip enabled, map type)
      managedMcpServers = lib.mapAttrs (name: mcp: {
        command = mcp.command;
        args = mcp.args or [];
        env = mcp.env or {};
      } // lib.optionalAttrs (mcp.type == "local" || mcp.type == "stdio") {
        type = "stdio";
      } // lib.optionalAttrs (mcp.type != "local" && mcp.type != "stdio" && mcp ? type) {
        type = mcp.type;
      }) cfg.mcps;

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
      # Wrapper script for oh-my-claudecode (binary is named 'omc')
      omcBin = pkgs.writeShellScriptBin "omc" ''
        set -euo pipefail

        # Suppress Node.js deprecation warnings
        export NODE_NO_WARNINGS=1

        NPM_GLOBAL_DIR="$HOME/.npm-global"
        NPM_GLOBAL_BIN="$NPM_GLOBAL_DIR/bin"
        OMC_BIN="$NPM_GLOBAL_BIN/omc"

        # Ensure npm global directory exists and is configured
        mkdir -p "$NPM_GLOBAL_DIR"
        ${pkgs.nodejs_22}/bin/npm config set prefix "$NPM_GLOBAL_DIR" 2>/dev/null || true

        # Install oh-my-claudecode if not present
        if [ ! -x "$OMC_BIN" ]; then
          echo "Installing oh-my-claudecode..."
          PATH="$NPM_GLOBAL_BIN:$PATH" ${pkgs.nodejs_22}/bin/npm install -g claudecode-omc@latest
        fi

        ${
          if (!isDarwin) then
            ''
              exec "${claudeCodeFHS}/bin/claude-fhs" "$OMC_BIN" "$@"
            ''
          else
            ''
              exec "$OMC_BIN" "$@"
            ''
        }
      '';
    in
    {
      imports = [ ./options.nix ];

      config = {
        # Set default router settings from imported config
        jvf.programs.claudecode.routerSettings = lib.mkDefault defaultRouterConfig;

        # Inject MCP servers into settings automatically
        jvf.programs.claudecode.settings = {
          mcpServers = lib.mkDefault (lib.mapAttrs (name: mcp: {
            command = mcp.command;
            args = mcp.args or [];
            env = mcp.env or {};
          } // lib.optionalAttrs (mcp.type == "local" || mcp.type == "stdio") {
            type = "stdio";
          } // lib.optionalAttrs (mcp.type != "local" && mcp.type != "stdio" && mcp ? type) {
            type = mcp.type;
          }) cfg.mcps);
        };

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
              ".credentials.json"
              "mcp-needs-auth-cache.json"
              "sessions"
              "backups"
              "plans"
              "session-env"
              "plugins"
            ];
            packages = [
              claudeCodeBin
              omcBin
            ];
            configPath = ".claude";
            configs = lib.mkMerge [
              (inputs.lib.aiTools.mkClaudecodeMdConfigs "agents" cfg.agents)
              (inputs.lib.aiTools.mkClaudecodeMdConfigs "commands" cfg.commands)
              (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
              (lib.mkIf (cfg.settings != { }) {
                "settings.json" = cfg.settings;
              })
            ];
            postInstall = ''
              CLAUDE_JSON="${if isDarwin then "/Users" else "/home"}/${cfg.username}/.claude.json"
              SETTINGS_JSON="${if isDarwin then "/Users" else "/home"}/${cfg.username}/.claude/settings.json"
              if [ -f "$SETTINGS_JSON" ]; then
                if [ ! -f "$CLAUDE_JSON" ]; then
                  echo "{}" > "$CLAUDE_JSON"
                fi
                # Overwrite .mcpServers in ~/.claude.json with the one from our generated settings.json
                ${lib.getExe pkgs.jq} --argjson newMcp "$(${lib.getExe pkgs.jq} '.mcpServers // {}' "$SETTINGS_JSON")" '.mcpServers = $newMcp' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp"
                mv -f "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
                chown ${cfg.username}:${if isDarwin then "staff" else "users"} "$CLAUDE_JSON"
              fi
            '';
          };
          claude-code-router = {
            preserveFiles = [
              "logs"
              "plugins"
              ".credentials.json"
              "mcp-needs-auth-cache.json"
              "sessions"
              "plans"
              "session-env"
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
          mcpServers = managedMcpServers;
        };
      }
      // lib.optionalAttrs isDarwin {
        system.activationScripts.claudeCodeMcp.text = ''
          targetDir="/Library/Application Support/ClaudeCode"
          targetFile="$targetDir/managed-mcp.json"

          # Define the content in the Nix store (immutable)
          sourceFile="${pkgs.writeText "managed-mcp.json" (builtins.toJSON { mcpServers = managedMcpServers; })}"

          echo "Configuring Claude Code Managed MCP..."
          mkdir -p "$targetDir"

          # Symlink the immutable file to the target location
          ln -sf "$sourceFile" "$targetFile"
        '';
      };
    };
in
{
  flake.modules.nixos.programs-claudecode = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-claudecode = mkConfig { isDarwin = true; };
}
