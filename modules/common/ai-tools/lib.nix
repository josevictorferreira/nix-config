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

  # Helper to import agent/command files that may be functions or plain attrsets
  # This handles the transition period where some files use mkAgent/mkCommand (functions)
  # and others are still plain attrsets with markdown strings
  importAiFile = lib: file:
    let imported = import file;
    in if builtins.isFunction imported
    then imported { inherit lib; }
    else imported;

  # Convert agent/command to Markdown format (for backward compatibility)
  # This is used by opencode/claudecode which expect markdown strings
  # Handles both structured format { name, description, prompt, ... } and plain markdown strings
  toMarkdownPrompt = value:
    if builtins.isAttrs value && value ? prompt
    then value.prompt  # Structured format - extract prompt field
    else value; # Plain markdown string - return as is

  # Extract all tools from a set of agents/commands
  extractTools = agentsOrCommands:
    lib.flatten (lib.mapAttrsToList (name: cfg: cfg.tools or [ ]) agentsOrCommands);

  # Generate tool disable settings from a list of tool names
  # Example: ["shadcn" "playwright"] -> { "shadcn*" = false; "playwright*" = false; }
  mkToolDisableSettings = tools:
    lib.listToAttrs (map (tool: { name = "${tool}*"; value = false; }) tools);
}
