{
  lib,
  config,
  ...
}:

let
  cfg = config.jvf.aiTools.mcp."ck";
in
{
  options.jvf.aiTools.mcp."ck" = {
    enable = (lib.mkEnableOption "CK Search MCP server") // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.mcps."ck" = {
      type = "local";
      enabled = true;
      command = [
        "ck"
        "serve"
      ];
    };

    jvf.programs.claudecode.mcps."ck" = {
      type = "stdio";
      command = "ck";
      args = [
        "--serve"
      ];
    };
  };
}
