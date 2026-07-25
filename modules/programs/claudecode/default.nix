# Aspect: programs-claudecode
# Defines jvf.programs.claudecode options for Claude Code and Claude Code Router.
# Config materialization via jvf.home; wrappers provide packages only.
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

      presets = {
        tokyonight = {
          format = "[░▒▓](#a3aed2)[ ](bg:#769ff0 fg:#a3aed2)$directory[ ](fg:#769ff0 bg:#394260)$git_branch$git_status[ ](fg:#394260 bg:#212736)$claude_model[ ](fg:#212736)";
          directory = {
            style = "fg:#e3e5e5 bg:#769ff0";
            format = "[ $path ]($style)";
            truncation_length = 3;
            truncation_symbol = "…/";
          };
          git_branch = {
            style = "bg:#394260";
            symbol = "";
            format = "[$symbol $branch]($style)";
          };
          git_status = {
            style = "bg:#394260";
            format = "[$all_status$ahead_behind ]($style)";
          };
          claude_model = {
            style = "bg:#212736";
            format = "[$model]($style)";
          };
        };
      };

      statuslineConfig =
        if (cfg.theme == "default") then
          cfg.statusline
        else
          lib.recursiveUpdate (presets.${cfg.theme} or { }) cfg.statusline;

      # FHS environment for Linux (npm global bins need glibc, etc.)
      nodeFHS =
        if (!isDarwin) then
          pkgs.buildFHSEnv
            {
              name = "node-fhs";
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
              runScript = "${pkgs.writeShellScript "node-runner" ''
              exec "$@"
            ''}";
            }
        else
          null;

      # Wrapper script for claude-code
      # Transform raw mcps into Claude Code's expected schema (strip enabled, map type)
      managedMcpServers = lib.mapAttrs
        (
          name: mcp:
            {
              command = mcp.command;
              args = mcp.args or [ ];
              env = mcp.env or { };
            }
            // lib.optionalAttrs (mcp.type == "local" || mcp.type == "stdio") {
              type = "stdio";
            }
            // lib.optionalAttrs (mcp.type != "local" && mcp.type != "stdio" && mcp ? type) {
              type = mcp.type;
            }
        )
        cfg.mcps;

      claudeCodeBin = pkgs.writeShellScriptBin "claude" ''
        set -euo pipefail

        # Suppress Node.js deprecation warnings
        export NODE_NO_WARNINGS=1

        # Hindsight memory configuration. Per-project granularity lives in
        # ~/.hindsight/claude-code.json (dynamicBankGranularity=["project"]
        # with resolveWorktrees=true). Granularity isn't an env-var knob.
        export HINDSIGHT_API_URL="https://hindsight-api.josevictor.me"
        export HINDSIGHT_DYNAMIC_BANK_ID="true"
        export HINDSIGHT_AUTO_RECALL="true"
        export HINDSIGHT_AUTO_RETAIN="true"
        export HINDSIGHT_RECALL_BUDGET="mid"

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

        # Auto-install plugins once
        PLUGINS_SENTINEL="$HOME/.claude/.plugins-installed-v3"
        if [ ! -f "$PLUGINS_SENTINEL" ] && [ -x "$CLAUDE_BIN" ]; then
          echo "Installing hindsight-memory plugin..."
          ${
            if (!isDarwin) then
              ''"${nodeFHS}/bin/node-fhs" "$CLAUDE_BIN"''
            else
              ''"$CLAUDE_BIN"''
          } plugin marketplace add vectorize-io/hindsight 2>/dev/null || true
          ${
            if (!isDarwin) then
              ''"${nodeFHS}/bin/node-fhs" "$CLAUDE_BIN"''
            else
              ''"$CLAUDE_BIN"''
          } plugin install hindsight-memory 2>/dev/null || true

          echo "Installing oh-my-claudecode plugin..."
          ${
            if (!isDarwin) then
              ''"${nodeFHS}/bin/node-fhs" "$CLAUDE_BIN"''
            else
              ''"$CLAUDE_BIN"''
          } plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode 2>/dev/null || true
          ${
            if (!isDarwin) then
              ''"${nodeFHS}/bin/node-fhs" "$CLAUDE_BIN"''
            else
              ''"$CLAUDE_BIN"''
          } plugin install oh-my-claudecode 2>/dev/null || true

          mkdir -p "$HOME/.claude"
          touch "$PLUGINS_SENTINEL"
        fi

        ${
          if (!isDarwin) then
            ''
              exec "${nodeFHS}/bin/node-fhs" "$CLAUDE_BIN" "$@"
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
              exec "${nodeFHS}/bin/node-fhs" "$ROUTER_BIN" "$@"
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
          PATH="$NPM_GLOBAL_BIN:$PATH" ${pkgs.nodejs_22}/bin/npm install -g oh-my-claude-sisyphus@latest
        fi

        ${
          if (!isDarwin) then
            ''
              exec "${nodeFHS}/bin/node-fhs" "$OMC_BIN" "$@"
            ''
          else
            ''
              exec "$OMC_BIN" "$@"
            ''
        }
      '';

      # Statusline script rendering oh-my-claudecode's HUD (wired via settings.statusLine)
      omcHudBin = pkgs.writeShellScriptBin "omc-hud" ''
        set -euo pipefail

        # Suppress Node.js deprecation warnings
        export NODE_NO_WARNINGS=1

        HUD_ENTRY="$HOME/.npm-global/lib/node_modules/oh-my-claude-sisyphus/dist/hud/index.js"

        # Stay silent until `omc` has installed the npm package
        if [ ! -f "$HUD_ENTRY" ]; then
          exit 0
        fi

        ${
          if (!isDarwin) then
            ''
              exec "${nodeFHS}/bin/node-fhs" node "$HUD_ENTRY"
            ''
          else
            ''
              exec ${pkgs.nodejs_22}/bin/node "$HUD_ENTRY"
            ''
        }
      '';

      # Build .claude config directory as a derivation for jvf.home
      claudeConfigs =
        (inputs.lib.aiTools.mkClaudecodeMdConfigs "agents" cfg.agents)
        // (inputs.lib.aiTools.mkClaudecodeMdConfigs "commands" cfg.commands)
        // (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
        // (lib.optionalAttrs (cfg.baseRules != "") {
          "CLAUDE.md" = cfg.baseRules;
        })
        // (lib.optionalAttrs (cfg.settings != { }) {
          "settings.json" = cfg.settings;
        });

      claudeConfigDir = pkgs.linkFarm "claude-config" (
        lib.mapAttrsToList
          (
            fileName: fileValue:
              let
                filePath =
                  if builtins.isString fileValue then
                    pkgs.writeText "claude-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue
                  else if builtins.isAttrs fileValue then
                    pkgs.writeText "claude-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}"
                      (
                        inputs.lib.generators.toFileFormatStr (lib.last (lib.splitString "." fileName)) fileValue
                      )
                  else
                    fileValue;
              in
              {
                name = fileName;
                path = filePath;
              }
          )
          claudeConfigs
      );

      # Build .claude-code-router config directory
      routerConfigDir = pkgs.linkFarm "claude-router-config" [
        {
          name = "config.json";
          path = pkgs.writeText "claude-router-config.json" (builtins.toJSON cfg.routerSettings);
        }
      ];
    in
    {
      imports = [ ./options.nix ];

      config = {
        # Set default router settings from imported config
        jvf.programs.claudecode.routerSettings = lib.mkDefault defaultRouterConfig;

        # Inject plugins and MCP servers into settings automatically
        jvf.programs.claudecode.settings = {
          statusLine = lib.mkDefault {
            type = "command";
            command = "${omcHudBin}/bin/omc-hud";
            padding = 0;
          };
          enabledPlugins = lib.mkDefault {
            "hindsight-memory@hindsight" = true;
            "oh-my-claudecode@omc" = true;
          };
          extraKnownMarketplaces = lib.mkDefault {
            hindsight = {
              source = {
                source = "github";
                repo = "vectorize-io/hindsight";
              };
            };
            omc = {
              source = {
                source = "git";
                url = "https://github.com/Yeachan-Heo/oh-my-claudecode.git";
              };
            };
          };
          mcpServers = lib.mkDefault (
            lib.mapAttrs
              (
                name: mcp:
                  {
                    command = mcp.command;
                    args = mcp.args or [ ];
                    env = mcp.env or { };
                  }
                  // lib.optionalAttrs (mcp.type == "local" || mcp.type == "stdio") {
                    type = "stdio";
                  }
                  // lib.optionalAttrs (mcp.type != "local" && mcp.type != "stdio" && mcp ? type) {
                    type = mcp.type;
                  }
              )
              cfg.mcps
          );
        };

        jvf.wrappers.users.${cfg.username}.programs = {
          claude.packages = [
            claudeCodeBin
            omcBin
          ];
          claude-code-router.packages = [
            claudeRouterBin
          ];
        };

        # Config materialization via jvf.home
        jvf.home.users.${cfg.username}.items = {
          ".claude" = {
            kind = "dir";
            mode = "copy";
            source = claudeConfigDir;
            preserve = [
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
              "sessions-index.json"
              "sessions-index.jsonl"
              "backups"
              "plans"
              "session-env"
              "plugins"
            ];
            postInstall = ''
              CLAUDE_JSON="$HOME_DIR/.claude.json"
              SETTINGS_JSON="$TARGET_PATH/settings.json"
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
          ".claude-code-router" = {
            kind = "dir";
            mode = "copy";
            source = routerConfigDir;
            preserve = [
              "logs"
              "plugins"
              ".credentials.json"
              "mcp-needs-auth-cache.json"
              "sessions"
              "plans"
              "session-env"
              ".claude-code-router.pid"
            ];
          };
        }
        // lib.optionalAttrs (statuslineConfig != { }) {
          ".config/claude-code-statusline.toml" = {
            kind = "file";
            mode = "copy";
            toml = statuslineConfig;
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
          sourceFile="${
            pkgs.writeText "managed-mcp.json" (builtins.toJSON { mcpServers = managedMcpServers; })
          }"

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
