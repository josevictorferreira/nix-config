{ lib
, pkgs
, config
, username
, system
, inputs
, ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.gemini;
in
{
  options.jvf.programs.gemini = {
    enable = lib.mkEnableOption "Install gemini-cli and write per-user ~/.gemini/config.json";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    baseRules = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "A set of base rules to apply to the Gemini configuration";
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Agents to install into the configuration (string prompts or structured objects)";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Skills to install into the configuration (string prompts or structured objects)";
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

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.gemini/settings.json";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: Add gemini-cli package when available in nixpkgs
    # For now, users can install manually via: npm install -g gemini-cli

    jvf.wrappers.users.${cfg.username}.programs.gemini = {
      packages = [ ];
      configPath = ".gemini";
      configs = lib.mkMerge [
        (inputs.lib.aiTools.mkGeminiMdConfigs config.jvf.aiTools.mcp "agent" cfg.agents)
        (inputs.lib.aiTools.mkGeminiTOMLConfigs config.jvf.aiTools.mcp "command" cfg.commands)
        (inputs.lib.aiTools.mkSkillConfigs cfg.skills)
        {
          "settings.json" = {
            mcpServers = cfg.mcps;
          } // cfg.settings;
          "AGENTS.md" = cfg.baseRules;
        }
      ];
    };
  };
}
