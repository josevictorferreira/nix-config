# Aspect: programs-pi
# Defines jvf.programs.pi options for the Pi coding agent.
# Config materialization via jvf.home; wrappers provide the package.
# Pi loads skills from ~/.pi/agent/skills/ and prompt templates from ~/.pi/agent/prompts/.
# Skills use the Agent Skills standard (same as opencode/claudecode/gemini).
# Commands from ai-tools are mapped to pi prompt templates.
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.programs.pi;
      json = pkgs.formats.json { };

      # Convert an ai-tools command definition to a pi prompt template
      toPiPromptTemplate =
        value:
        if builtins.isAttrs value && value ? prompt then
          let
            description = value.description or "";
            prompt = value.prompt or "";
            headerLines = lib.optional (description != "") "description: ${builtins.toJSON description}";
            yamlHeader =
              if headerLines != [ ] then "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n\n" else "";
          in
          yamlHeader + prompt
        else
          builtins.trace "WARNING: Using deprecated plain Markdown string format for pi prompt. Please migrate to structured format." value;

      mkPiPromptConfigs =
        attrset:
        lib.mapAttrs'
          (name: value: {
            name = "${name}.md";
            value = toPiPromptTemplate value;
          })
          attrset;

      # Build pi agent config directory contents
      piAgentConfigs =
        (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
        // (mkPiPromptConfigs (cfg.commands // cfg.agents))
        // {
          # Pi's resource-loader (core/resource-loader.js) only auto-loads
          # AGENTS.md / AGENTS.MD / CLAUDE.md / CLAUDE.MD as system-prompt
          # context — not rules.md. (Pi cascades: ~/.pi/agent/AGENTS.md
          # global, plus every ancestor of cwd, all concatenated.)
          #
          # The tool whitelist section is pi-intrinsic — pi only ships
          # `read`, `bash`, `edit`, `write` — so models calling sub-agent
          # tools like `explore`/`glob` produce client-side `ModelMessage`
          # validation errors before the request even leaves pi. The fan-out
          # via jvf.aiTools.baseRule.content is appended below.
          "AGENTS.md" =
            ""
            + lib.optionalString (cfg.baseRules != "") ''

              ## Base Rules

              ${cfg.baseRules}
            '';
        }
        // (lib.optionalAttrs (cfg.settings != { }) {
          "settings.json" = cfg.settings;
        })
        // (lib.optionalAttrs (cfg.models != { }) {
          "models.json" = cfg.models;
        });

      piAgentDir = pkgs.linkFarm "pi-agent-config" (
        lib.mapAttrsToList
          (
            fileName: fileValue:
              let
                filePath =
                  if lib.isDerivation fileValue then
                    fileValue
                  else if builtins.isString fileValue then
                    pkgs.writeText "pi-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue
                  else if builtins.isAttrs fileValue then
                    pkgs.writeText "pi-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}"
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
          piAgentConfigs
      );

      # Build the pi settings file that points to skills and prompts directories
      piSettings = {
        skills = [ "skills" ];
        prompts = [ "prompts" ];
      }
      // cfg.settings;
    in
    {
      options.jvf.programs.pi = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing Pi configuration to.";
        };

        baseRules = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Base rules content, materialized as a prompt template.";
        };

        agents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Pi prompt templates derived from agent definitions.";
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Pi skills to install (Agent Skills standard).";
        };

        commands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Pi prompt templates derived from command definitions.";
        };

        mcps = lib.mkOption {
          type = lib.types.attrsOf json.type;
          default = { };
          description = "MCP servers configuration (passed through to settings if supported).";
        };

        settings = lib.mkOption {
          inherit (json) type;
          default = { };
          description = "Pi settings.json contents.";
        };

        models = lib.mkOption {
          inherit (json) type;
          default = { };
          description = ''
            Pi models.json contents. Custom providers and models loaded by pi at
            startup (see pi-coding-agent docs/models.md). Top-level shape:
            `{ providers = { name = { baseUrl, api, apiKey, models = [...]; }; }; }`.
          '';
        };

        extensions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "npm:pi-commandcode-provider" ];
          description = ''
            Pi extension specs passed verbatim to `pi install` whenever the
            declared list changes. Each entry should be a spec pi understands,
            e.g. `"npm:pi-commandcode-provider"` or shorthand `"pi-commandcode-provider"`.
            Installs happen during activation via a sentinel-tracked postInstall hook.
          '';
        };
      };

      imports = [
        ./_/provider.nix
      ];

      config = {
        jvf.wrappers.users.${cfg.username}.programs.pi = {
          packages = [ pkgs.pi-coding-agent ];
        };

        jvf.home.users.${cfg.username}.items = {
          ".pi/agent" = {
            kind = "dir";
            mode = "copy";
            source = piAgentDir;
            preserve = [
              "history"
              "state"
              "cache"
              "sessions"
              # Pi mutates these at runtime (theme, installed packages list,
              # OAuth tokens). Without preserving them, jvf.home re-syncs the
              # agent dir on every rebuild and nukes pi's own state — which
              # cascades into pi npm-pruning extensions whose `packages` entry
              # has vanished.
              "settings.json"
              "auth.json"
              ".nix-extensions.json"
            ];
            postInstall = ''
              # Ensure the skills and prompts subdirectories exist
              mkdir -p "$TARGET_PATH/skills" "$TARGET_PATH/prompts"

              # Settings merge: keep user-written content (e.g. pi's `packages`
              # key after `pi install`) and layer our generated keys on top.
              SETTINGS_FILE="$TARGET_PATH/settings.json"
              if [ ! -f "$SETTINGS_FILE" ]; then
                echo '{}' > "$SETTINGS_FILE"
              fi
              ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$SETTINGS_FILE" "$TARGET_PATH/settings.json" > "$SETTINGS_FILE.tmp" 2>/dev/null || cp "$TARGET_PATH/settings.json" "$SETTINGS_FILE.tmp"
              mv -f "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

              # Activation runs as root and copies from the read-only nix store;
              # hand ownership + write bit back to the user so pi can mutate
              # settings.json at runtime (pi install/remove rewrites it).
              chown -R "$USER_NAME:$GROUP_NAME" "$TARGET_PATH"
              chmod -R u+w "$TARGET_PATH"

              # Run `pi install` for each declared extension whenever the
              # desired list differs from the last-applied state. Sentinel
              # lives in the agent dir alongside other runtime state.
              EXT_STATE="$TARGET_PATH/.nix-extensions.json"
              DESIRED=${lib.escapeShellArg (builtins.toJSON cfg.extensions)}
              CURRENT="$(cat "$EXT_STATE" 2>/dev/null || echo '[]')"
              if [ "$DESIRED" != "$CURRENT" ]; then
                PI=${lib.escapeShellArg "${pkgs.pi-coding-agent}/bin/pi"}
                if [ -x "$PI" ]; then
                  if [ "$(id -u)" -eq 0 ] && command -v runuser >/dev/null 2>&1; then
                    run_pi() { runuser -u "$USER_NAME" -- env "HOME=$HOME_DIR" "$PI" "$@"; }
                  else
                    run_pi() { env "HOME=$HOME_DIR" "$PI" "$@"; }
                  fi
                  ${lib.concatMapStringsSep "\n" (ext: ''
                    echo "[pi] Installing extension: ${ext}"
                    run_pi install ${lib.escapeShellArg ext} \
                      || echo "[pi] WARN: failed to install ${ext}"
                  '') cfg.extensions}
                  echo "$DESIRED" > "$EXT_STATE"
                  chown "$USER_NAME:$GROUP_NAME" "$EXT_STATE"
                fi
              fi
            '';
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-pi = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-pi = mkConfig { isDarwin = true; };
}
