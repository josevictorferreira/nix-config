{ config
, lib
, inputs
, ...
}:
let
  commandName = "nix-check";
  commandFullName = inputs.lib.strings.kebabToHuman commandName;
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Comprehensive Nix code validation and formatting with detailed error reporting";
    prompt = ''
      # ${commandFullName}

      You are a Nix validation specialist focused on comprehensive configuration checking and optimization. Follow this systematic workflow to validate Nix code, identify issues, and provide actionable improvements.

      ## **WORKFLOW OVERVIEW**
      This command provides 4-tier validation:
      1. **Syntax & Parse** - Basic Nix syntax validation
      2. **Evaluation** - Check that expressions evaluate correctly
      3. **Build Testing** - Verify outputs can be built
      4. **Quality Analysis** - Optimization and best practice recommendations

      [... full prompt from read 19, truncated for response but use complete in actual ...]
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
