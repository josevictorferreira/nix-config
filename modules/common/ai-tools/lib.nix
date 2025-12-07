{ lib }:

let
  types = lib.types;

  aiOptions = {
    name = lib.mkOption {
      type = types.str;
      description = lib.mdDoc "Name of the AI agent or command.";
    };

    description = lib.mkOption {
      type = types.str;
      description = lib.mdDoc "Brief description of what it does.";
    };

    tools = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = lib.mdDoc "List of tools this agent/command uses.";
    };

    prompt = lib.mkOption {
      type = types.lines;
      description = lib.mdDoc "The multi-line prompt defining the agent's behavior.";
    };
  };
in
rec {
  types = {
    aiDefinition = types.submodule ({ ... }: {
      options = aiOptions;
    });
  };

  mkAgent = { name ? throw "mkAgent requires 'name'", description ? throw "mkAgent requires 'description'", prompt ? throw "mkAgent requires 'prompt'", tools ? [ ], ... }: {
    inherit name description tools prompt;
  };

  mkCommand = mkAgent;

  # Helper to fold agents/commands into attrset
  foldAiDefinitions = defs: lib.foldl' lib.recursiveUpdate { } defs;
}
