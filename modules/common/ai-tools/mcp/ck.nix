{ lib
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."ck";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "ck";
    tags = [ "explorer" ];
    config = {
      jvf.programs.opencode.mcps."ck" = {
        type = "local";
        enabled = true;
        command = [
          "${lib.getExe config.jvf.programs."ck-search".package}"
          "--serve"
        ];
      };

      jvf.programs.claudecode.mcps."ck" = {
        type = "stdio";
        command = "${lib.getExe config.jvf.programs."ck-search".package}";
        args = [
          "--serve"
        ];
      };

      jvf.programs.droid.mcps."ck" = {
        type = "stdio";
        command = "${lib.getExe config.jvf.programs."ck-search".package}";
        args = [
          "--serve"
        ];
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."ck" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
