# config/permission.nix - Permission configurations for OpenCode
{ config, lib, ... }:
let
  cfg = config.jvf.programs.opencode;
  # Generate wildcard patterns for all MCP names (deny by default)
  mcpPermissions = lib.mapAttrs'
    (name: _value: {
      name = "${name}*";
      value = "allow";
    })
    cfg.mcps;
in
{
  config.jvf.programs.opencode.settings.permission = lib.mkMerge [
    mcpPermissions
    {
      edit = "allow";
      bash = {
        "*" = "allow";
      };
      read = "allow";
      list = "allow";
      glob = "allow";
      grep = "allow";
      webfetch = "allow";
      write = "allow";
      task = "allow";
      todowrite = "allow";
      todoread = "allow";
      lsp = "allow";
      skill = "allow";
      question = "allow";
    }
  ];
}
