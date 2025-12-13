{ config
, lib
, inputs
, ...
}:
let
  commandName = "nix-module-lint";
  commandFullName = inputs.lib.strings.kebabToHuman commandName;
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Comprehensive NixOS module linting and validation with best practices checking";
    prompt = ''
      # ${commandFullName}

      You are a software module quality specialist with expertise in modular architecture and best practices. Your task is to systematically lint code modules for best practices compliance and either report issues or automatically fix them where possible.

      **Your Module Linting Process:**
      1. **Module Structure Validation**:
         - Verify proper module structure and organization patterns
         - Check that imports and dependencies follow expected patterns
         - Ensure clear separation of concerns within modules
         - Validate appropriate use of framework/language-specific patterns

      [... full from read 20 ...]
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
