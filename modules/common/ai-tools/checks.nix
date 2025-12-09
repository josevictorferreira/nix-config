{ lib, pkgs, system }:

let
  # Evaluate ai-tools as a proper module to get typed config values
  evalResult = lib.evalModules {
    modules = [
      ./default.nix
      {
        config.jvf.aiTools.enable = true;
      }
    ];
    specialArgs = { inherit lib pkgs system; };
  };

  aiCfg = evalResult.config.jvf.aiTools;

  agents = aiCfg.agents;
  commands = aiCfg.commands;
  mcp = aiCfg.mcp;

  enabledAgents = lib.filterAttrs (_: v: v.enable or false) agents;
  enabledCommands = lib.filterAttrs (_: v: v.enable or false) commands;
  enabledMcp = lib.filterAttrs (_: v: v.enable or false) mcp;

  # Tool collection
  allTools = lib.unique (
    lib.flatten (
      lib.mapAttrsToList (_: cfg: cfg.tools or [ ]) (agents // commands)
    )
  );
  enabledTools = lib.unique (
    lib.flatten (
      lib.mapAttrsToList (_: cfg: cfg.tools or [ ]) (enabledAgents // enabledCommands)
    )
  );

  # Validate required fields on structured definitions
  validateDefinition = name: value:
    let
      hasRequiredFields =
        (value.name or "") != ""
        && (value.description or "") != ""
        && (value.prompt or "") != "";
    in
    {
      inherit name hasRequiredFields;
    };

  agentValidations = lib.mapAttrsToList validateDefinition agents;
  commandValidations = lib.mapAttrsToList validateDefinition commands;

  invalidAgents = builtins.filter (v: !v.hasRequiredFields) agentValidations;
  invalidCommands = builtins.filter (v: !v.hasRequiredFields) commandValidations;

  # MCP dependency validation
  requiredMcpTools = lib.filter (tool: builtins.hasAttr tool mcp) enabledTools;
  missingRequiredMcp = lib.filter (tool: !(builtins.hasAttr tool enabledMcp)) requiredMcpTools;

  platformSpecificMcp = {
    "mcp-nixos" = "linux";
  };

  isDarwin = builtins.match ".*-darwin" system != null;

  wrongPlatformMcp = lib.filterAttrs
    (name: _: (builtins.hasAttr name platformSpecificMcp)
      && ((platformSpecificMcp.${name} == "linux" && isDarwin)
      || (platformSpecificMcp.${name} == "darwin" && !isDarwin)))
    enabledMcp;

  stats = {
    agents = {
      total = builtins.length agentValidations;
      invalid = builtins.length invalidAgents;
      enabled = builtins.length (builtins.attrNames enabledAgents);
    };
    commands = {
      total = builtins.length commandValidations;
      invalid = builtins.length invalidCommands;
      enabled = builtins.length (builtins.attrNames enabledCommands);
    };
    tools = {
      total = builtins.length allTools;
      enabled = builtins.length enabledTools;
      unique = allTools;
    };
    mcp = {
      total = builtins.length (builtins.attrNames mcp);
      enabled = builtins.length (builtins.attrNames enabledMcp);
      missingRequired = builtins.length missingRequiredMcp;
      wrongPlatform = builtins.length (builtins.attrNames wrongPlatformMcp);
    };
  };

  validationReport = pkgs.writeText "ai-tools-validation-report.txt" ''
    AI-Tools Module Validation Report
    ==================================
    Platform: ${system}

    AGENTS
    ------
    Total:      ${toString stats.agents.total}
    Enabled:    ${toString stats.agents.enabled}
    Invalid:    ${toString stats.agents.invalid}

    ${lib.optionalString (stats.agents.invalid > 0) ''
      Invalid Agents:
      ${lib.concatMapStringsSep "\n" (v: "  - ${v.name}: missing name/description/prompt") invalidAgents}
    ''}

    COMMANDS
    --------
    Total:      ${toString stats.commands.total}
    Enabled:    ${toString stats.commands.enabled}
    Invalid:    ${toString stats.commands.invalid}

    ${lib.optionalString (stats.commands.invalid > 0) ''
      Invalid Commands:
      ${lib.concatMapStringsSep "\n" (v: "  - ${v.name}: missing name/description/prompt") invalidCommands}
    ''}

    TOOLS
    -----
    Unique tools referenced (all definitions): ${toString stats.tools.total}
    Unique tools referenced (enabled): ${toString stats.tools.enabled}
    ${lib.concatMapStringsSep "\n" (t: "  - ${t}") enabledTools}

    MCP SERVERS
    -----------
    Total defined:        ${toString stats.mcp.total}
    Enabled:              ${toString stats.mcp.enabled}
    Missing required MCP: ${toString stats.mcp.missingRequired}
    Wrong platform:       ${toString stats.mcp.wrongPlatform}

    ${lib.optionalString (stats.mcp.missingRequired > 0) ''
      Missing required MCP servers for referenced tools:
      ${lib.concatMapStringsSep "\n" (t: "  - ${t}") missingRequiredMcp}
    ''}

    ${lib.optionalString (stats.mcp.wrongPlatform > 0) ''
      Wrong Platform MCP Servers:
      ${lib.concatMapStringsSep "\n" (name: "  - ${name} (should only be on ${platformSpecificMcp.${name}})") (builtins.attrNames wrongPlatformMcp)}
    ''}

    VALIDATION RESULT
    -----------------
    ${if stats.agents.invalid > 0 || stats.commands.invalid > 0 || stats.mcp.missingRequired > 0 then "FAILED" else "PASSED"}
    ${lib.optionalString (stats.mcp.wrongPlatform > 0) "WARNING: Platform-specific MCP servers enabled on wrong platform"}
  '';

  assertions = [
    {
      assertion = missingRequiredMcp == [ ];
      message = "AI tools reference MCP tools that are disabled or missing: ${lib.concatStringsSep ", " missingRequiredMcp}";
    }
    {
      assertion = stats.agents.invalid == 0 && stats.commands.invalid == 0;
      message = "All agents and commands must provide name, description, and prompt";
    }
    {
      assertion = !(isDarwin && builtins.hasAttr "mcp-nixos" enabledMcp);
      message = "mcp-nixos must not be enabled on Darwin systems";
    }
  ] ++ lib.optional (builtins.hasAttr "nix-expert" enabledAgents) {
    assertion = (!enabledAgents."nix-expert".enable) || ((builtins.hasAttr "context7" enabledMcp) && (enabledMcp.context7.enable or false));
    message = "nix-expert agent requires context7 MCP to be enabled";
  };

  assertionsCheck = pkgs.runCommand "ai-tools-assertions-check"
    {
      buildInputs = [ pkgs.coreutils ];
    } ''
    ${lib.optionalString (missingRequiredMcp != [ ]) ''
      echo "ERROR: Missing required MCP servers for tools: ${lib.concatStringsSep ", " missingRequiredMcp}"
      exit 1
    ''}

    ${lib.optionalString (stats.agents.invalid > 0 || stats.commands.invalid > 0) ''
      echo "ERROR: Found invalid AI definitions (missing name/description/prompt)"
      exit 1
    ''}

    ${lib.optionalString (isDarwin && enabledMcp ? "mcp-nixos") ''
      echo "ERROR: mcp-nixos enabled on Darwin"
      exit 1
    ''}

    echo "AI-Tools assertions passed"
    mkdir -p $out
    echo "success" > $out/result
  '';

  requiredFieldsCheck = pkgs.runCommand "ai-tools-required-fields-check" { } ''
    ${lib.optionalString (stats.agents.invalid > 0) ''
      echo "ERROR: ${toString stats.agents.invalid} agents missing required fields"
      exit 1
    ''}

    ${lib.optionalString (stats.commands.invalid > 0) ''
      echo "ERROR: ${toString stats.commands.invalid} commands missing required fields"
      exit 1
    ''}

    mkdir -p $out
    echo "All structured definitions have required fields" > $out/result
  '';

  evalCheck = pkgs.runCommand "ai-tools-eval-check"
    {
      buildInputs = [ pkgs.nix ];
      agentsJson = builtins.toJSON (builtins.attrNames agents);
      commandsJson = builtins.toJSON (builtins.attrNames commands);
      mcpJson = builtins.toJSON (builtins.attrNames mcp);
    } ''
    echo "Agents: $agentsJson"
    echo "Commands: $commandsJson"
    echo "MCP servers: $mcpJson"

    mkdir -p $out
    echo "AI-Tools module evaluated successfully" > $out/result
  '';

in
{
  inherit validationReport stats;

  checks = {
    inherit assertionsCheck requiredFieldsCheck evalCheck;

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

  validations = {
    inherit agentValidations commandValidations invalidAgents invalidCommands;
    inherit allTools enabledTools enabledMcp missingRequiredMcp wrongPlatformMcp;
    inherit assertions;
  };
}
