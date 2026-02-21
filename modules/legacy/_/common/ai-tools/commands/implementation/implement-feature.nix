{ config
, lib
, inputs
, ...
}:
let
  commandName = "implement-feature";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Plan and proceed to implement a new feature based on a prompt enhanced by a specified (or defaulted) model.";
    agent = "build";
    prompt = ''
      !`prompt-enhancer feature "$ARGUMENTS";`
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
