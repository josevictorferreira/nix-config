{
  config,
  lib,
  inputs,
  ...
}:
let
  commandName = "implement-tests";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Plan and proceed to implement tests based on a prompt enhanced by a specified (or defaulted) model.";
    agent = "build";
    prompt = ''
      !`prompt-enhancer tests \"$ARGUMENTS\";`
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
