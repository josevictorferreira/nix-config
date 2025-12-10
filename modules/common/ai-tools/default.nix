{
  lib,
  config ? { },
  ...
}@args:

let
  aiLib = import ./lib.nix args;
  cfg = config.jvf.aiTools;
in
{
  imports = [
    (import ./mcp/default.nix { inherit lib aiLib; })
    (import ./agents/default.nix { inherit lib aiLib; })
    (import ./commands/default.nix { inherit lib aiLib; })
  ];

  options.jvf.aiTools = {
    enable = lib.mkEnableOption "AI tools integration";

    commands = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Custom AI commands to register.";
    };

    agents = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Custom AI agents to register.";
    };

    mcp = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Custom AI MCP tools to register.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.aiTools.commands = lib.mapAttrs (name: cmd: { enable = true; }) cfg.commands;
    jvf.aiTools.agents = lib.mapAttrs (name: cmd: { enable = true; }) cfg.agents;
    jvf.aiTools.mcp = lib.mapAttrs (name: cmd: { enable = true; }) cfg.mcp;
  };
}
