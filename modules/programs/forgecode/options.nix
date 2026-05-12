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
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "Provider ID";
          };
          api_key = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "API key for the provider (use env var references like '$ENV_VAR')";
          };
          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "URL for the provider API";
          };
          models = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of available models";
          };
        };
      });
      default = { };
      description = "AI provider configurations for ForgeCode";
    };
  };
}
