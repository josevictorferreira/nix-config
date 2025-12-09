{ lib }:

let
  types = lib.types;
  aiTypes = import ./types.nix { inherit lib; };

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
  aiToolsLib = {
    inherit toMarkdownPrompt toClaudeMarkdownPrompt toOpencodeMarkdownPrompt extractTools mkToolDisableSettings;
  };

  types = {
    aiDefinition = types.submodule ({ ... }: {
      options = aiOptions;
    });
    inherit (aiTypes) agentType commandType mcpLocalType mcpRemoteType mcpType;
  };

  mkAgentModule = def: {

    options = {
      enable = lib.mkEnableOption "AI agent";
      name = lib.mkOption { type = types.str; default = def.name or ""; description = lib.mdDoc "Display name for the agent."; };
      description = lib.mkOption { type = types.str; default = def.description or ""; description = lib.mdDoc "Short description of the agent."; };
      tools = lib.mkOption { type = types.listOf types.str; default = def.tools or [ ]; description = lib.mdDoc "List of tools the agent may use."; };
      prompt = lib.mkOption { type = types.lines; default = def.prompt or ""; description = lib.mdDoc "Multi-line prompt defining the agent."; };
      _output = lib.mkOption { type = types.attrsOf types.anything; default = { }; readOnly = true; description = lib.mdDoc "Computed consumer output (reserved)."; };
    };
  };

  mkCommandModule = def: {
    options = {
      enable = lib.mkEnableOption "AI command";
      name = lib.mkOption { type = types.str; default = def.name or ""; description = lib.mdDoc "Display name for the command."; };
      description = lib.mkOption { type = types.str; default = def.description or ""; description = lib.mdDoc "Short description of the command."; };
      tools = lib.mkOption { type = types.listOf types.str; default = def.tools or [ ]; description = lib.mdDoc "List of tools the command may use."; };
      prompt = lib.mkOption { type = types.lines; default = def.prompt or ""; description = lib.mdDoc "Multi-line prompt defining the command."; };
      _output = lib.mkOption { type = types.attrsOf types.anything; default = { }; readOnly = true; description = lib.mdDoc "Computed consumer output (reserved)."; };
    };
  };

  mkMcpModule = def: {
    options = {
      enable = lib.mkEnableOption "MCP server";
      _output = lib.mkOption { type = types.attrsOf types.anything; default = { }; readOnly = true; description = lib.mdDoc "Computed consumer output (reserved)."; };
    } // (def.options or { });
    config = def.config or { };
  };

  # Legacy helpers (kept for backward compatibility during migration)
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
    then
    # SKILL.md format with YAML frontmatter
      let
        yamlHeader = ''
          ---
          name: "${value.name or "unknown"}"
          description: "${value.description or ""}"
          ${if (value ? tools && value.tools != [ ]) then "tools:" else ""}
          ${lib.optionalString (value ? tools && value.tools != [ ]) (lib.concatMapStringsSep "\n" (tool: "  ${tool}: true") value.tools)}
          ---

        '';
      in
      yamlHeader + value.prompt
    else
    # Plain markdown string - DEPRECATED format
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  # Convert agent/command to Claude-specific Markdown format
  # Uses "allowed-tools" key with comma-separated string instead of YAML dict
  toClaudeMarkdownPrompt = value:
    if builtins.isAttrs value && value ? prompt
    then
    # SKILL.md format with YAML frontmatter (Claude format)
      let
        toolsString = lib.concatStringsSep ", " value.tools;
        yamlHeader = ''
          ---
          name: "${value.name or "unknown"}"
          description: "${value.description or ""}"
          ${lib.optionalString (value ? tools && value.tools != [ ]) "allowed-tools: \"${toolsString}\""}
          ---

        '';
      in
      yamlHeader + value.prompt
    else
    # Plain markdown string - DEPRECATED format
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  # Convert agent/command to opencode-specific Markdown format
  # Adds "*" suffix and lowercases tool names (opencode requirement)
  toOpencodeMarkdownPrompt = value:
    if builtins.isAttrs value && value ? prompt
    then
    # SKILL.md format with YAML frontmatter (opencode format)
      let
        yamlHeader = ''
          ---
          name: "${value.name or "unknown"}"
          description: "${value.description or ""}"
          ${if (value ? tools && value.tools != [ ]) then "tools:" else ""}
          ${lib.optionalString (value ? tools && value.tools != [ ]) (lib.concatMapStringsSep "\n" (tool: "  ${lib.toLower tool}*: true") value.tools)}
          ---

        '';
      in
      yamlHeader + value.prompt
    else
    # Plain markdown string - DEPRECATED format
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  # Extract all tools from a set of agents/commands
  extractTools = agentsOrCommands:
    lib.flatten (lib.mapAttrsToList (_: cfg: cfg.tools or [ ]) agentsOrCommands);

  # Generate tool disable settings from a list of tool names
  # Example: ["shadcn" "playwright"] -> { "shadcn*" = false; "playwright*" = false; }
  mkToolDisableSettings = tools:
    lib.listToAttrs (map (tool: { name = "${tool}*"; value = false; }) tools);
}
