{
  config,
  lib,
  inputs,
  ...
}:
let
  commandName = "do";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Enhance and run a prompt using a specified (or defaulted) model.";
    agent = "build";
    prompt = ''
      !`prompt-enhancer bare \"$ARGUMENTS\";`
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
