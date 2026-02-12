{ lib
, pkgs
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."mcp-nixos";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "mcp-nixos";
    tags = [ "nix" ];
    mcpNames = {
      opencode = "mcp-nixos";
      claudecode = "nixos-mcp";
    };
    mcpOptions = {
      opencode = {
        type = "local";
        enabled = true;
        command = [ (lib.getExe pkgs.mcp-nixos) ];
      };
      claudecode = {
        type = "stdio";
        enabled = true;
        command = lib.getExe pkgs.mcp-nixos;
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."mcp-nixos" = mcpDef.options // {
    enable = mcpDef.options.enable // { default = false; };
  };

  config = lib.mkIf cfg.enable mcpDef.config;
}
