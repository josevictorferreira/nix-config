{ config
, lib
, inputs
, ...
}:
let
  commandName = "implement-feature";
  commandFullName = inputs.lib.strings.kebabToHuman commandName;
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Plan and proceed to implement a new feature based on a prompt enhanced by a specified (or defaulted) model.";
    prompt = ''
      # ${commandFullName}

      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
