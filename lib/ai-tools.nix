{ lib
, ...
}:

let
  toolTags = [
    "frontend"
    "browser"
    "explorer"
    "container"
    "documentation"
    "nix"
  ];

  mkSkillModule =
    { name
    , description ? ""
    , prompt ? ""
    , model ? ""
    , tags ? [ ]
    , allowed-tools ? [ ]
    , mcp ? { }
    , references ? { }
    , scripts ? { }
    , licence ? ""
    , metadata ? { }
    ,
    }:
    let
      skillDefinition = {
        inherit
          name
          description
          model
          prompt
          tags
          mcp
          references
          scripts
          licence
          metadata
          ;
        "allowed-tools" = allowed-tools;
      };
    in
    {
      options = {
        enable = (lib.mkEnableOption name) // {
          default = true;
        };
        tags = lib.mkOption {
          type = lib.types.listOf (lib.types.enum toolTags);
          default = tags;
          description = "Capability tags for ${name}";
        };
      };
      config = {
        jvf.programs.opencode.skills.${name} = skillDefinition;
        jvf.programs.claudecode.skills.${name} = skillDefinition;
        jvf.programs.droid.skills.${name} = skillDefinition;
        jvf.programs.gemini.skills.${name} = skillDefinition;
      };
    };

  formatPermissions =
    perms: indent:
    let
      formatValue =
        key: value:
        if builtins.isString value then
          "${indent}\"${key}\": \"${value}\""
        else if builtins.isAttrs value then
          "${indent}\"${key}\":\n${formatPermissions value "${indent}  "}"
        else
          "";
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList formatValue perms);

  mkAgentModule =
    { name
    , model ? ""
    , mode ? "primary"
    , temperature ? null
    , permission ? { }
    , description ? ""
    , prompt ? ""
    , tags ? [ ]
    , tools ? [ ]
    , disabledTools ? [ ]
    ,
    }:
    {
      options = {
        enable = (lib.mkEnableOption name) // {
          default = true;
        };
        tags = lib.mkOption {
          type = lib.types.listOf (lib.types.enum toolTags);
          default = tags;
          description = "Capability tags for ${name}";
          example = [
            "explorer"
            "documentation"
          ];
        };
      };
      config = {
        jvf.programs.opencode.agents.${name} = {
          inherit
            name
            mode
            model
            temperature
            permission
            description
            prompt
            tags
            tools
            disabledTools
            ;
        };
        jvf.programs.droid.agents.${name} = {
          inherit
            name
            mode
            model
            temperature
            permission
            description
            prompt
            tags
            tools
            disabledTools
            ;
        };
        jvf.programs.claudecode.agents.${name} = {
          inherit
            name
            mode
            model
            temperature
            permission
            description
            prompt
            tags
            tools
            disabledTools
            ;
        };
        jvf.programs.gemini.agents.${name} = {
          inherit
            name
            mode
            model
            temperature
            permission
            description
            prompt
            tags
            tools
            disabledTools
            ;
        };
      };
    };

  mkMcpModule =
    { name ? "MCP Server"
    , tags ? [ ]
    , config ? { }
    ,
    }:
    {
      options = {
        enable = (lib.mkEnableOption name) // {
          default = true;
        };
        tags = lib.mkOption {
          type = lib.types.listOf (lib.types.enum toolTags);
          default = tags;
          description = "Capability tags for ${name}";
          example = [ "documentation-search" ];
        };
      };
      config = config;
    };

  mkCommandModule =
    { name
    , description ? ""
    , agent ? ""
    , prompt ? ""
    ,
    }:
    {
      options = {
        enable = (lib.mkEnableOption name) // {
          default = true;
        };
      };
      config = {
        jvf.programs.opencode.commands.${name} = {
          inherit
            name
            description
            agent
            prompt
            ;
        };
        jvf.programs.droid.commands.${name} = {
          inherit
            name
            description
            agent
            prompt
            ;
        };
        jvf.programs.claudecode.commands.${name} = {
          inherit
            name
            description
            agent
            prompt
            ;
        };
        jvf.programs.gemini.commands.${name} = {
          inherit
            name
            description
            agent
            prompt
            ;
        };
      };
    };

  findToolsByTags =
    mcpConfigs: tags:
    let
      matchingMcps = lib.filterAttrs
        (
          _: cfg: (cfg.enable or false) && (lib.any (tag: lib.elem tag tags) (cfg.tags or [ ]))
        )
        mcpConfigs;
    in
    builtins.attrNames matchingMcps;

  toClaudeMarkdownPrompt =
    mcpConfigs: value:
    if builtins.isAttrs value && value ? prompt then
      let
        explicitTools = value.tools or [ ];
        tagTools = if value ? tags then (findToolsByTags mcpConfigs value.tags) else [ ];
        allTools = lib.unique (explicitTools ++ tagTools);
        toolsString = lib.concatStringsSep ", " allTools;
        headerLines = [
          "name: \"${value.name or "unknown"}\""
          "description: \"${value.description or ""}\""
        ]
        ++ lib.optional (allTools != [ ]) "allowed-tools: \"${toolsString}\""
        ++ lib.optional ((builtins.hasAttr "agent" value) && value.agent != "") "agent: ${value.agent}"
        ++ lib.optional ((builtins.hasAttr "model" value) && value.model != "") "model: ${value.model}"
        ++ lib.optional
          (
            (builtins.hasAttr "temperature" value) && value.temperature != null
          ) "temperature: ${toString value.temperature}";
        yamlHeader = "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n";
      in
      yamlHeader + value.prompt
    else
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  toOpencodeMarkdownPrompt =
    mcpConfigs: value:
    if builtins.isAttrs value && value ? prompt then
      let
        explicitTools = value.tools or [ ];
        disabledTools = value.disabledTools or [ ];
        tagTools = if value ? tags then (findToolsByTags mcpConfigs value.tags) else [ ];
        allTools = lib.unique (explicitTools ++ tagTools);
        headerLines = [
          "name: \"${value.name or "unknown"}\""
          "description: \"${value.description or ""}\""
          "mode: \"${value.mode or "subagent"}\""
        ]
        ++ lib.optional (builtins.hasAttr "permission" value && value.permission != { }) "permission:"
        ++ lib.optionals (builtins.hasAttr "permission" value && value.permission != { }) (
          lib.mapAttrsToList
            (
              key: perm:
                if builtins.isString perm then
                  "  \"${key}\": \"${perm}\""
                else if builtins.isAttrs perm then
                  "  \"${key}\":\n${formatPermissions perm "    "}"
                else
                  ""
            )
            value.permission
        )
        ++ lib.optional (allTools != [ ]) "tools:"
        ++ lib.optionals (allTools != [ ]) (
          (map (tool: "  ${lib.toLower tool}*: true") allTools)
            ++ (map (tool: "  ${lib.toLower tool}*: false") disabledTools)
        )
        ++ lib.optional ((builtins.hasAttr "agent" value) && value.agent != "") "agent: ${value.agent}"
        ++ lib.optional ((builtins.hasAttr "model" value) && value.model != "") "model: ${value.model}"
        ++ lib.optional
          (
            (builtins.hasAttr "temperature" value) && value.temperature != null
          ) "temperature: ${toString value.temperature}";
        yamlHeader = "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n";
      in
      yamlHeader + value.prompt
    else
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  toCursorMarkdownPrompt =
    mcpConfigs: value:
    if builtins.isAttrs value && value ? prompt then
      let
        explicitTools = value.tools or [ ];
        tagTools = if value ? tags then (findToolsByTags mcpConfigs value.tags) else [ ];
        allTools = lib.unique (explicitTools ++ tagTools);

        fmtTool = tool: if lib.hasPrefix "@" tool then tool else "@${tool}";

        headerLines = [
          "description: \"${value.description or (value.name or "")}\""
        ]
        ++
        lib.optional (value ? alwaysApply)
          "alwaysApply: ${if value.alwaysApply then "true" else "false"}"
        ++ lib.optionals (value ? globs && value.globs != [ ]) (
          [ "globs:" ] ++ map (g: "  - \"${g}\"") value.globs
        );

        yamlHeader = "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n";

        toolsPreamble =
          if allTools == [ ] then
            ""
          else
            "\n## Preferred MCP tools\n" + (lib.concatStringsSep ", " (map fmtTool allTools)) + "\n\n";
      in
      yamlHeader + toolsPreamble + value.prompt
    else
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  mkCursorMdcConfigs =
    mcpConfigs: prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.mdc";
        value = toCursorMarkdownPrompt mcpConfigs value;
      })
      attrset;

  toSkillMarkdown =
    skillName: skill:
    let
      allowedToolsYaml =
        if skill ? allowed-tools && skill.allowed-tools != [ ] then
          "allowed-tools:\n" + lib.concatMapStringsSep "\n" (tool: "  - ${tool}*") skill.allowed-tools
        else
          "";

      formatMcp =
        mcp: indent:
        let
          formatValue =
            name: cfg:
            let
              argsStr =
                if cfg ? args then
                  "    args: [ " + (lib.concatStringsSep ", " (map (arg: "\"${arg}\"") cfg.args)) + " ]"
                else
                  "";
              commandStr = if cfg ? command then "    command: \"${cfg.command}\"" else "";
            in
            "${indent}${name}:\n${indent}${commandStr}\n${indent}${argsStr}";
        in
        "mcp:\n" + (lib.concatStringsSep "\n" (lib.mapAttrsToList (name: cfg: formatValue name cfg) mcp));

      mcpYaml =
        if skill ? mcp && skill.mcp != { } then
          formatMcp skill.mcp "  "
        else
          "";

      formatMetadata =
        metadata:
        let
          formatValue =
            key: value:
            if builtins.isString value then
              "  ${key}: ${value}"
            else if builtins.isList value then
              "  ${key}: [${lib.concatStringsSep ", " (map (v: "\"${v}\"") value)}]"
            else
              "";
        in
        "metadata:\n" + (lib.concatStringsSep "\n" (lib.mapAttrsToList formatValue metadata));

      metadataYaml =
        if skill ? metadata && skill.metadata != { } then
          formatMetadata skill.metadata
        else
          "";

      headerLines = [
        "name: \"${skillName}\""
        "description: \"${skill.description or ""}\""
      ]
      ++ lib.optional ((builtins.hasAttr "model" skill) && skill.model != "") "model: ${skill.model}"
      ++ lib.optional ((builtins.hasAttr "licence" skill) && skill.licence != "") "licence: ${skill.licence}"
      ++ lib.optional (metadataYaml != "") metadataYaml
      ++ lib.optional (allowedToolsYaml != "") allowedToolsYaml
      ++ lib.optional (mcpYaml != "") mcpYaml
      ++ lib.optional true "compatibility: opencode";
      yamlHeader = "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n";
    in
    yamlHeader + "\n" + (skill.prompt or "");

  mkSingleSkillConfigs =
    skillName: skill:
    let
      # Main SKILL.md file
      skillMd = {
        "skill/${skillName}/SKILL.md" = toSkillMarkdown skillName skill;
      };

      # Reference files
      references =
        if skill ? references && skill.references != { } then
          lib.mapAttrs'
            (refName: refContent: {
              name = "skill/${skillName}/references/${refName}.md";
              value = refContent;
            })
            skill.references
        else
          { };

      # Script files
      scripts =
        if skill ? scripts && skill.scripts != { } then
          lib.mapAttrs'
            (scriptName: scriptContent: {
              name = "skill/${skillName}/scripts/${scriptName}";
              value = scriptContent;
            })
            skill.scripts
        else
          { };
    in
    skillMd // references // scripts;

  mkSingleSkillsConfigs =
    skillName: skill:
    let
      # Main SKILL.md file
      skillMd = {
        "skills/${skillName}/SKILL.md" = toSkillMarkdown skillName skill;
      };

      # Reference files
      references =
        if skill ? references && skill.references != { } then
          lib.mapAttrs'
            (refName: refContent: {
              name = "skills/${skillName}/references/${refName}.md";
              value = refContent;
            })
            skill.references
        else
          { };

      # Script files
      scripts =
        if skill ? scripts && skill.scripts != { } then
          lib.mapAttrs'
            (scriptName: scriptContent: {
              name = "skills/${skillName}/scripts/${scriptName}";
              value = scriptContent;
            })
            skill.scripts
        else
          { };
    in
    skillMd // references // scripts;

  mkSkillConfigs =
    skills:
    lib.foldl' (acc: skillName: acc // (mkSingleSkillConfigs skillName skills.${skillName})) { } (
      builtins.attrNames skills
    );

  mkSkillsConfigs =
    skills:
    lib.foldl' (acc: skillName: acc // (mkSingleSkillsConfigs skillName skills.${skillName})) { } (
      builtins.attrNames skills
    );

  mkOpencodeMdConfigs =
    mcpConfigs: prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = toOpencodeMarkdownPrompt mcpConfigs value;
      })
      attrset;

  mkGeminiMdConfigs =
    mcpConfigs: prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = toOpencodeMarkdownPrompt mcpConfigs value;
      })
      attrset;

  # Escape TOML string values (handles quotes and backslashes)
  escapeTomlString = str:
    builtins.replaceStrings [ "\\" "\"" "\n" "\t" ] [ "\\\\" "\\\"" "\\n" "\\t" ] str;

  # Replace !`...` with !{...} for Gemini CLI tool invocation syntax
  replaceBacktickToolSyntax = str:
    let
      parts = builtins.split "!\`([^\`]*)\`" str;
      processedParts = builtins.map
        (part:
          if builtins.isList part then
            "!{${builtins.elemAt part 0}}"
          else
            part
        )
        parts;
    in
    builtins.concatStringsSep "" processedParts;

  # Replace $1, $2, etc. with {{args}} for Gemini CLI
  replaceNumberedArgs = str:
    let
      parts = builtins.split "\\$[0-9]+" str;
      processedParts = builtins.map
        (part:
          if builtins.isList part then
            "{{args}}"
          else
            part
        )
        parts;
    in
    builtins.concatStringsSep "" processedParts;

  # Apply all Gemini-specific prompt transformations
  transformGeminiPrompt = str:
    let
      withArgs = builtins.replaceStrings [ "$ARGUMENTS" ] [ "{{args}}" ] str;
      withNumberedArgs = replaceNumberedArgs withArgs;
    in
    replaceBacktickToolSyntax withNumberedArgs;

  # Convert command/agent definition to Gemini CLI TOML format
  toGeminiToml = value:
    if builtins.isAttrs value && value ? prompt then
      let
        description = value.description or "";
        rawPrompt = value.prompt or "";
        prompt = transformGeminiPrompt rawPrompt;
        # Build TOML content
        descriptionLine =
          if description != "" then
            "description = \"${escapeTomlString description}\"\n\n"
          else
            "";
        # Use multi-line literal string for prompt (triple quotes)
        promptLine = "prompt = \"\"\"\n${prompt}\n\"\"\"";
      in
      descriptionLine + promptLine
    else
      builtins.trace "WARNING: Using deprecated plain string format for Gemini. Please migrate to structured format with mkCommand." ''
        prompt = """
        ${transformGeminiPrompt value}
        """
      '';

  # Generate TOML config files for Gemini CLI commands
  # Places files in commands/<name>.toml format
  mkGeminiTomlConfigs =
    attrset:
    lib.mapAttrs'
      (name: value: {
        name = "commands/${name}.toml";
        value = toGeminiToml value;
      })
      attrset;

  mkClaudecodeMdConfigs =
    mcpConfigs: prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = toClaudeMarkdownPrompt mcpConfigs value;
      })
      attrset;
in
{
  inherit
    mkSingleSkillConfigs
    mkSkillConfigs
    mkSkillsConfigs
    toSkillMarkdown
    toOpencodeMarkdownPrompt
    toClaudeMarkdownPrompt
    mkOpencodeMdConfigs
    mkClaudecodeMdConfigs
    mkCursorMdcConfigs
    mkMcpModule
    mkAgentModule
    mkCommandModule
    mkSkillModule
    findToolsByTags
    mkGeminiMdConfigs
    toGeminiToml
    mkGeminiTomlConfigs
    escapeTomlString
    ;
}
