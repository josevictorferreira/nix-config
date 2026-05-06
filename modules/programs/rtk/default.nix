# Aspect: programs-rtk
# Builds RTK (Rust Token Killer) and wires hooks into claudecode + opencode.
# RTK reduces LLM token consumption 60-90% by rewriting CLI commands.
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.rtk;

      rtkPkg = pkgs.rustPlatform.buildRustPackage {
        pname = "rtk";
        version = "0.37.2";

        src = pkgs.fetchFromGitHub {
          owner = "rtk-ai";
          repo = "rtk";
          rev = "v0.37.2";
          hash = "sha256-rNuu8B5TnKZHrbVSV8HkcTeTdcol26259GGJEPEMPZY=";
        };

        cargoHash = "sha256-61+PNuVF8H5+9PHc3MBt8V80ieBBi8HzSC9Gc/WUSzM=";

        nativeBuildInputs = with pkgs; [
          pkg-config
          cmake
        ];

        buildInputs = [ pkgs.openssl ];

        meta = {
          description = "Rust Token Killer - CLI proxy that reduces LLM token consumption 60-90%";
          homepage = "https://github.com/rtk-ai/rtk";
          license = lib.licenses.mit;
          mainProgram = "rtk";
        };

        doCheck = false;
      };

      rtkClaudeHook = pkgs.writeShellScript "rtk-claude-hook" ''
        #!/usr/bin/env bash
        # rtk-hook-version: 3
        # RTK Claude Code hook -- rewrites commands to use rtk for token savings.

        CACHE_DIR=''${XDG_CACHE_HOME:-$HOME/.cache}
        CACHE_FILE="$CACHE_DIR/rtk-hook-version-ok"
        if [ ! -f "$CACHE_FILE" ]; then
          RTK_VERSION_RAW=$(${rtkPkg}/bin/rtk --version 2>/dev/null)
          RTK_VERSION=''${RTK_VERSION_RAW#rtk }
          RTK_VERSION=''${RTK_VERSION%% *}
          if [ -n "$RTK_VERSION" ]; then
            IFS=. read -r MAJOR MINOR PATCH <<<"$RTK_VERSION"
            if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 23 ]; then
              echo "[rtk] WARNING: rtk $RTK_VERSION is too old (need >= 0.23.0)" >&2
              exit 0
            fi
          fi
          mkdir -p "$CACHE_DIR" 2>/dev/null
          touch "$CACHE_FILE" 2>/dev/null
        fi

        INPUT=$(cat)
        CMD=$(${pkgs.jq}/bin/jq -r '.tool_input.command // empty' <<<"$INPUT")

        if [ -z "$CMD" ]; then
          exit 0
        fi

        REWRITTEN=$(${rtkPkg}/bin/rtk rewrite "$CMD" 2>/dev/null)
        EXIT_CODE=$?

        case $EXIT_CODE in
          0)
            [ "$CMD" = "$REWRITTEN" ] && exit 0
            ;;
          1)
            exit 0
            ;;
          2)
            exit 0
            ;;
          3)
            ;;
          *)
            exit 0
            ;;
        esac

        if [ "$EXIT_CODE" -eq 3 ]; then
          ${pkgs.jq}/bin/jq -c --arg cmd "$REWRITTEN" \
            '.tool_input.command = $cmd | {
              "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "updatedInput": .tool_input
              }
            }' <<<"$INPUT"
        else
          ${pkgs.jq}/bin/jq -c --arg cmd "$REWRITTEN" \
            '.tool_input.command = $cmd | {
              "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "RTK auto-rewrite",
                "updatedInput": .tool_input
              }
            }' <<<"$INPUT"
        fi
      '';

      rtkOpenCodePlugin = pkgs.writeText "rtk-opencode-plugin.ts" ''
        import type { Plugin } from "@opencode-ai/plugin"
        export const RtkOpenCodePlugin: Plugin = async ({ $ }) => {
          try { await $`which ${rtkPkg}/bin/rtk`.quiet() } catch {
            console.warn("[rtk] rtk binary not found -- plugin disabled")
            return {}
          }
          return {
            "tool.execute.before": async (input, output) => {
              const tool = String(input?.tool ?? "").toLowerCase()
              if (tool !== "bash" && tool !== "shell") return
              const args = output?.args
              if (!args || typeof args !== "object") return
              const command = (args as Record<string, unknown>).command
              if (typeof command !== "string" || !command) return
              try {
                const result = await $`${rtkPkg}/bin/rtk rewrite ''${command}`.quiet().nothrow()
                const rewritten = String(result.stdout).trim()
                if (rewritten && rewritten !== command) {
                  ;(args as Record<string, unknown>).command = rewritten
                }
              } catch {}
            },
          }
        }
      '';
    in
    {
      options.jvf.programs.rtk = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install RTK";
        };
      };

      config = {
        # Expose rtk binary
        jvf.wrappers.users.${cfg.username}.programs.rtk.packages = [ rtkPkg ];

        # Wire Claude Code PreToolUse hook
        jvf.programs.claudecode.settings.hooks = {
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${rtkClaudeHook}";
                }
              ];
            }
          ];
        };

        # Deploy OpenCode plugin
        jvf.programs.opencode.extraConfigFiles."plugins/rtk.ts" = rtkOpenCodePlugin;
      };
    };
in
{
  flake.modules.nixos.programs-rtk = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-rtk = mkConfig { isDarwin = true; };
}
