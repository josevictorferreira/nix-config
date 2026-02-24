# Droid options definitions
{ config, lib, ... }:
{
  options.jvf.programs.droid = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username to install the program";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Settings written to ~/.factory/settings.json";
    };
    baseRules = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "A set of base rules to apply to the OpenCode configuration.";
    };
    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.attrs);
      default = { };
      description = "Agents to install into the configuration (string prompts or structured objects)";
    };
    commands = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.attrs);
      default = { };
      description = "Commands to install into the configuration (string prompts or structured objects)";
    };
    mcps = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "MCP tools to install into the configuration (structured objects)";
    };
    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.attrs);
      default = { };
      description = "Skills to install into the configuration";
    };
  };
}
