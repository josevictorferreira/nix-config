# Options for ForgeCode AI coding tool
{ config, lib, ... }:

{
  options.jvf.programs.forgecode = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for installing packages to.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "The forgecode package to install.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Settings written to ~/.forge/.forge.toml";
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Agents to install into the configuration";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Skills to install into the configuration (co-installed via aiTools DSL)";
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Custom commands for ForgeCode (markdown with YAML frontmatter)";
    };

    mcps = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "MCP servers configuration";
    };

    providers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              description = "Provider ID";
            };
            api_key_var = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Environment variable that contains the provider API key";
            };
            url = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "URL for the provider API";
            };
            response_type = lib.mkOption {
              type = lib.types.enum [
                "OpenAI"
                "OpenAIResponses"
                "Anthropic"
                "Bedrock"
                "Google"
                "OpenCode"
              ];
              default = "OpenAI";
              description = "Wire protocol used by the provider";
            };
            models = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Known model IDs for this provider";
            };
          };
        }
      );
      default = { };
      description = "AI provider configurations for ForgeCode";
    };
  };
}
