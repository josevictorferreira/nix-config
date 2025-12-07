{ lib, pkgs, system }:

let
  aiTools = import ./default.nix { inherit lib pkgs system; };
  aiLib = aiTools.lib;

  # Helper to validate agent/command structure
  validateAiDefinition = name: value:
    let
      isStructured = builtins.isAttrs value && value ? name && value ? description && value ? prompt;
      isLegacy = builtins.isString value;
      hasRequiredFields = isStructured && value.name != "" && value.description != "" && value.prompt != "";
    in
    {
      inherit name;
      valid = isStructured || isLegacy;
      structured = isStructured;
      hasRequiredFields = hasRequiredFields;
      issues = lib.optionals (!isStructured && !isLegacy) [ "Not a structured definition or legacy string" ]
        ++ lib.optionals (isStructured && !hasRequiredFields) [ "Missing required fields (name, description, or prompt)" ];
    };

  # Validate all agents
  agentValidations = lib.mapAttrsToList validateAiDefinition aiTools.agents;

  # Validate all commands
  commandValidations = lib.mapAttrsToList validateAiDefinition aiTools.commands;

  # Check for invalid definitions
  invalidAgents = builtins.filter (v: !v.valid) agentValidations;
  invalidCommands = builtins.filter (v: !v.valid) commandValidations;

  # Extract tools from all agents
  allAgentTools = aiLib.extractTools aiTools.agents;
  allCommandTools = aiLib.extractTools aiTools.commands;
  allTools = lib.unique (allAgentTools ++ allCommandTools);

  # Get enabled MCP servers (those with at least one agent enabled)
  enabledMcpServers = lib.filterAttrs
    (name: cfg:
      cfg ? opencode && cfg.opencode ? enabled && cfg.opencode.enabled == true
    )
    aiTools.mcp;

  # Platform-specific MCP validation
  isDarwin = builtins.match ".*-darwin" system != null;
  platformSpecificMcp = {
    "mcp-nixos" = "linux";
  };

  # Check if MCP servers are appropriate for platform
  wrongPlatformMcp = lib.filterAttrs
    (name: cfg:
      platformSpecificMcp ? ${name} &&
      ((platformSpecificMcp.${name} == "linux" && isDarwin) ||
      (platformSpecificMcp.${name} == "darwin" && !isDarwin))
    )
    enabledMcpServers;

  # Statistics
  stats = {
    agents = {
      total = builtins.length agentValidations;
      structured = builtins.length (builtins.filter (v: v.structured) agentValidations);
      legacy = builtins.length (builtins.filter (v: !v.structured && v.valid) agentValidations);
      invalid = builtins.length invalidAgents;
    };
    commands = {
      total = builtins.length commandValidations;
      structured = builtins.length (builtins.filter (v: v.structured) commandValidations);
      legacy = builtins.length (builtins.filter (v: !v.structured && v.valid) commandValidations);
      invalid = builtins.length invalidCommands;
    };
    tools = {
      total = builtins.length allTools;
      unique = allTools;
    };
    mcp = {
      total = builtins.length (builtins.attrNames aiTools.mcp);
      enabled = builtins.length (builtins.attrNames enabledMcpServers);
      wrongPlatform = builtins.length (builtins.attrNames wrongPlatformMcp);
    };
  };

  # Generate validation report
  validationReport = pkgs.writeText "ai-tools-validation-report.txt" ''
    AI-Tools Module Validation Report
    ==================================
    Platform: ${system}
    Date: ${toString (builtins.currentTime)}

    AGENTS
    ------
    Total:      ${toString stats.agents.total}
    Structured: ${toString stats.agents.structured}
    Legacy:     ${toString stats.agents.legacy}
    Invalid:    ${toString stats.agents.invalid}

    ${lib.optionalString (stats.agents.invalid > 0) ''
      Invalid Agents:
      ${lib.concatMapStringsSep "\n" (v: "  - ${v.name}: ${lib.concatStringsSep ", " v.issues}") invalidAgents}
    ''}

    COMMANDS
    --------
    Total:      ${toString stats.commands.total}
    Structured: ${toString stats.commands.structured}
    Legacy:     ${toString stats.commands.legacy}
    Invalid:    ${toString stats.commands.invalid}

    ${lib.optionalString (stats.commands.invalid > 0) ''
      Invalid Commands:
      ${lib.concatMapStringsSep "\n" (v: "  - ${v.name}: ${lib.concatStringsSep ", " v.issues}") invalidCommands}
    ''}

    TOOLS
    -----
    Unique tools referenced: ${toString stats.tools.total}
    ${lib.concatMapStringsSep "\n" (t: "  - ${t}") allTools}

    MCP SERVERS
    -----------
    Total defined:        ${toString stats.mcp.total}
    Enabled for opencode: ${toString stats.mcp.enabled}
    Wrong platform:       ${toString stats.mcp.wrongPlatform}

    ${lib.optionalString (stats.mcp.wrongPlatform > 0) ''
      Wrong Platform MCP Servers:
      ${lib.concatMapStringsSep "\n" (name: "  - ${name} (should only be on ${platformSpecificMcp.${name}})") (builtins.attrNames wrongPlatformMcp)}
    ''}

    VALIDATION RESULT
    -----------------
    ${if stats.agents.invalid > 0 || stats.commands.invalid > 0 then "FAILED" else "PASSED"}
    ${lib.optionalString (stats.mcp.wrongPlatform > 0) "WARNING: Platform-specific MCP servers enabled on wrong platform"}
  '';

  # Create assertion-based checks
  assertionsCheck = pkgs.runCommand "ai-tools-assertions-check"
    {
      buildInputs = [ pkgs.coreutils ];
    } ''
    # Check for invalid agents
    ${lib.optionalString (stats.agents.invalid > 0) ''
      echo "ERROR: Found ${toString stats.agents.invalid} invalid agents"
      exit 1
    ''}

    # Check for invalid commands
    ${lib.optionalString (stats.commands.invalid > 0) ''
      echo "ERROR: Found ${toString stats.commands.invalid} invalid commands"
      exit 1
    ''}

    # Warn about platform-specific MCP
    ${lib.optionalString (stats.mcp.wrongPlatform > 0) ''
      echo "WARNING: Found ${toString stats.mcp.wrongPlatform} MCP servers on wrong platform"
    ''}

    echo "AI-Tools validation passed"
    echo "  Agents: ${toString stats.agents.total} (${toString stats.agents.structured} structured, ${toString stats.agents.legacy} legacy)"
    echo "  Commands: ${toString stats.commands.total} (${toString stats.commands.structured} structured, ${toString stats.commands.legacy} legacy)"
    echo "  MCP Servers: ${toString stats.mcp.enabled} enabled"
    echo "  Tools: ${toString stats.tools.total} unique"

    mkdir -p $out
    echo "success" > $out/result
  '';

  # Check that all structured definitions have required fields
  requiredFieldsCheck = pkgs.runCommand "ai-tools-required-fields-check"
    { } ''
    ${lib.concatMapStringsSep "\n"
      (v: lib.optionalString v.structured ''
        ${lib.optionalString (!v.hasRequiredFields) ''
          echo "ERROR: ${v.name} is structured but missing required fields"
          exit 1
        ''}
      '')
      (agentValidations ++ commandValidations)
    }

    mkdir -p $out
    echo "All structured definitions have required fields" > $out/result
  '';

  # Eval test - ensure ai-tools can be evaluated without errors
  evalCheck = pkgs.runCommand "ai-tools-eval-check"
    {
      buildInputs = [ pkgs.nix ];
      agentsJson = builtins.toJSON (builtins.mapAttrs (name: value: { inherit name; type = builtins.typeOf value; }) aiTools.agents);
      commandsJson = builtins.toJSON (builtins.mapAttrs (name: value: { inherit name; type = builtins.typeOf value; }) aiTools.commands);
      mcpJson = builtins.toJSON (builtins.attrNames aiTools.mcp);
    } ''
    echo "Agents structure: $agentsJson"
    echo "Commands structure: $commandsJson"
    echo "MCP servers: $mcpJson"

    mkdir -p $out
    echo "AI-Tools module evaluated successfully" > $out/result
  '';

in
{
  inherit validationReport stats;
  checks = {
    inherit assertionsCheck requiredFieldsCheck evalCheck;

    # Combined check
    all = pkgs.runCommand "ai-tools-all-checks"
      {
        buildInputs = [ assertionsCheck requiredFieldsCheck evalCheck ];
      } ''
      echo "Running all AI-Tools validation checks..."
      cat ${validationReport}

      mkdir -p $out
      echo "All checks passed" > $out/result
      cp ${validationReport} $out/validation-report.txt
    '';
  };

  # Expose validation data for use in other modules
  validations = {
    inherit agentValidations commandValidations invalidAgents invalidCommands;
    inherit allTools enabledMcpServers wrongPlatformMcp;
  };
}
