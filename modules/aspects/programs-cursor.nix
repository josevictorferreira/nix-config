# Aspect: programs-cursor
# Defines jvf.programs.cursor options for Cursor editor.
{ ... }:
let
  mkCursorOptions =
    { lib, pkgs, ... }:
    let
      json = pkgs.lib.formats.json { };
    in
    {
      options.jvf.programs.cursor = {
        enable = lib.mkEnableOption "Install cursor router and write per-user ~/.cursor-router/config.json";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to install the configuration";
        };
        baseRules = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "A set of base rules to apply to the Cursor configuration.";
        };
        agents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Agents to install into the configuration (string prompts or structured objects)";
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
        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Skills to install into the configuration";
        };
        settings = lib.mkOption {
          type = json.type;
          default = { };
          description = "Cursor settings.";
        };
      };
    };

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
      cfg = config.jvf.programs.cursor;
      json = pkgs.formats.json { };
      filteredSkills = lib.filterAttrs (
        _: skill: !(builtins.isAttrs skill && skill ? mcp && skill.mcp != { })
      ) cfg.skills;
    in
    {
      imports = [ mkCursorOptions ];

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.cursor = {
          packages = [
            pkgs.code-cursor
          ];
          configPath = ".cursor";
          configs = lib.mkMerge [
            (inputs.lib.aiTools.mkCursorMdcConfigs config.jvf.aiTools.mcp "agents" cfg.agents)
            (inputs.lib.aiTools.mkCursorMdcConfigs config.jvf.aiTools.mcp "commands" cfg.commands)
            (inputs.lib.aiTools.mkSkillsConfigs filteredSkills)
            {
              "mcp.json" = {
                mcpServers = cfg.mcps;
              };
              "settings.json" = cfg.settings;
            }
            (lib.optionalAttrs (cfg.baseRules != "") {
              "rules/base.mdc" = ''
                ---
                alwaysApply: true
                ---
                ${cfg.baseRules}
              '';
            })
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-cursor = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-cursor = mkConfig { isDarwin = true; };
}
