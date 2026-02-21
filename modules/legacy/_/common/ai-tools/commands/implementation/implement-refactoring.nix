{ config
, lib
, inputs
, ...
}:
let
  commandName = "implement-refactoring";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
    agent = "build";
    prompt = ''
      !`prompt-enhancer refactoring "$ARGUMENTS";`
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
