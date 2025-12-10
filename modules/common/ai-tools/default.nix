{
  lib,
  config,
  ...
}:

let
  cfg = config.jvf.aiTools;
in
{
  imports = [
    (import ./mcp/default.nix)
    (import ./agents/default.nix)
    (import ./commands/default.nix)
  ];

  options.jvf.aiTools = {
    enable = lib.mkEnableOption "AI tools integration";
  };
}
