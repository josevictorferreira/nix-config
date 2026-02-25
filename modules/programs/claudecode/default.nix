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
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.jvf.programs.claudecode;

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
      imports = [ ./options.nix ];

      config = {
          # Set default router settings from imported config
          jvf.programs.claudecode.routerSettings = lib.mkDefault defaultRouterConfig;

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
        };
    };
in
{
  flake.modules.nixos.programs-claudecode = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-claudecode = mkConfig { isDarwin = true; };
}
