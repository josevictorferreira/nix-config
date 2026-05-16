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
              if headerLines != [ ] then
                "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n\n"
              else
                "";
          in
          yamlHeader + prompt
        else
          builtins.trace "WARNING: Using deprecated plain Markdown string format for pi prompt. Please migrate to structured format." value;

      mkPiPromptConfigs =
        attrset:
        lib.mapAttrs'
          (
            name: value: {
              name = "${name}.md";
              value = toPiPromptTemplate value;
            }
          )
          attrset;

      # Build pi agent config directory contents
      piAgentConfigs =
        (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
        // (mkPiPromptConfigs (cfg.commands // cfg.agents))
        // (lib.optionalAttrs (cfg.baseRules != "") {
          "rules.md" = ''
            ---
            description: Base rules and conventions for this project
            ---

            ${cfg.baseRules}
          '';
        })
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
      piSettings =
        {
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
            ];
            postInstall = ''
              # Ensure the skills and prompts subdirectories exist
              mkdir -p "$TARGET_PATH/skills" "$TARGET_PATH/prompts"

              # Write settings.json if it doesn't exist or needs updating
              SETTINGS_FILE="$TARGET_PATH/settings.json"
              if [ ! -f "$SETTINGS_FILE" ]; then
                echo '{}' > "$SETTINGS_FILE"
              fi

              # Merge our generated settings with existing settings
              ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$SETTINGS_FILE" "$TARGET_PATH/settings.json" > "$SETTINGS_FILE.tmp" 2>/dev/null || cp "$TARGET_PATH/settings.json" "$SETTINGS_FILE.tmp"
              mv -f "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
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
