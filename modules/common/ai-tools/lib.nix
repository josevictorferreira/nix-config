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
  # DEPRECATED: Plain attrset format is deprecated. Use mkAgent/mkCommand instead.
  importAiFile = lib: file:
    let
      imported = import file;
      result =
        if builtins.isFunction imported
        then imported { inherit lib; }
        else imported;

      # Check if this is using the old plain string format and warn
      hasLegacyFormat = builtins.isAttrs result &&
        (lib.any (name: let value = result.${name}; in builtins.isString value || (builtins.isAttrs value && !(value ? name && value ? description && value ? prompt))) (builtins.attrNames result));

      warning =
        if hasLegacyFormat
        then builtins.trace "WARNING: ${file} uses deprecated Markdown string format. Please migrate to mkAgent/mkCommand. See AGENTS.md for details." result
        else result;
    in
    warning;

  # Convert agent/command to Markdown format (for backward compatibility)
  # This is used by opencode/claudecode which expect markdown strings
  # Handles both structured format { name, description, prompt, ... } and plain markdown strings
  # DEPRECATED: This function exists only for backward compatibility during migration.
  toMarkdownPrompt = value:
    if builtins.isAttrs value && value ? prompt
    then value.prompt  # Structured format - extract prompt field
    else
    # Plain markdown string - DEPRECATED format
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  # Extract all tools from a set of agents/commands
  extractTools = agentsOrCommands:
    lib.flatten (lib.mapAttrsToList (name: cfg: cfg.tools or [ ]) agentsOrCommands);

  # Generate tool disable settings from a list of tool names
  # Example: ["shadcn" "playwright"] -> { "shadcn*" = false; "playwright*" = false; }
  mkToolDisableSettings = tools:
    lib.listToAttrs (map (tool: { name = "${tool}*"; value = false; }) tools);
}
