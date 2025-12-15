{
  config,
  lib,
  inputs,
  ...
}:
let
  commandName = "ask";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Answer a question based on a prompt enhanced by a specified (or defaulted) model.";
    agent = "build";
    prompt = ''
      !`prompt-enhancer change \"$ARGUMENTS\";`
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
