# options.nix - OpenCode option definitions
{ config
, lib
, pkgs
, ...
}:
let
  json = pkgs.formats.json { };
in
{
  options.jvf.programs.opencode = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for which to install the configuration";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "1.4.11";
      example = "1.4.11";
      description = ''
        Pinned opencode release tag (from the anomalyco/opencode fork).
        Bumping this and rebuilding re-installs into ~/.opencode.
        No auto-update check is performed at launch.
      '';
    };

    baseRules = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "A set of base rules to apply to the OpenCode configuration.";
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

    ohMyOpenCodeSettings = lib.mkOption {
      inherit (json) type;
      default = { };
      description = "Settings written to ~/.config/opencode/oh-my-openagent.json";
    };

    settings = lib.mkOption {
      inherit (json) type;
      default = { };
      description = "Settings written to ~/.config/opencode/config.json";
    };

    extraConfigFiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.package);
      default = { };
      description = "Extra files to include in the opencode config dir (relative path → derivation/text)";
    };
  };
}
