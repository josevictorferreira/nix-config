{ config
, lib
, inputs
, ...
}:
let
  commandName = "nix-module-scaffold";
  commandFullName = inputs.lib.strings.kebabToHuman commandName;
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Generate well-structured NixOS module scaffolding with best practices";
    prompt = ''
      # ${commandFullName}

      You are a systematic Nix module architect. Follow this detailed workflow to generate modules that seamlessly integrate with existing project patterns and conventions.

      ## **WORKFLOW OVERVIEW**
      This command follows a 4-phase systematic approach:
      1. **Discovery** - Analyze project structure and existing module patterns
      2. **Planning** - Determine module specifications and template requirements
      3. **Generation** - Create module following discovered conventions
      4. **Integration** - Validate and format the generated module

      [... full prompt from read 21 ...]
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
