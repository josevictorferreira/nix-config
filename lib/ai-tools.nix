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
        yamlHeader = ''
          ---
          name: "${value.name or "unknown"}"
          description: "${value.description or ""}"
          ${lib.optionalString (allTools != [ ]) "allowed-tools: \"${toolsString}\""}
          ---
        '';
      in
      yamlHeader + value.prompt
    else
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  toOpencodeMarkdownPrompt =
    mcpConfigs: value:
    if builtins.isAttrs value && value ? prompt then
      let
        explicitTools = value.tools or [ ];
        tagTools = if value ? tags then (findToolsByTags mcpConfigs value.tags) else [ ];
        allTools = lib.unique (explicitTools ++ tagTools);
        yamlHeader = ''
          ---
          name: "${value.name or "unknown"}"
          description: "${value.description or ""}"
          ${if (allTools != [ ]) then "tools:" else ""}
          ${lib.optionalString (allTools != [ ]) (
            lib.concatMapStringsSep "\n" (tool: "  ${lib.toLower tool}*: true") allTools
          )}
          ---

        '';
      in
      yamlHeader + value.prompt
    else
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  toSkillMarkdown =
    skillName: skill:
    let
      allowedToolsYaml =
        if skill ? allowed-tools && skill.allowed-tools != [ ] then
          "allowed-tools:\n" + lib.concatMapStringsSep "\n" (tool: "  - ${tool}*") skill.allowed-tools
        else
          "";
      yamlHeader = ''
        ---
        name: ${skillName}
        description: ${skill.description or ""}
        ${lib.optionalString (skill ? license) "license: ${skill.license}"}
        ${allowedToolsYaml}
        ---
      '';
    in
    yamlHeader + "\n" + (skill.prompt or "");

  mkSingleSkillConfigs =
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

  mkOpencodeMdConfigs =
    mcpConfigs: prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = toOpencodeMarkdownPrompt mcpConfigs value;
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
    toSkillMarkdown
    toOpencodeMarkdownPrompt
    toClaudeMarkdownPrompt
    mkOpencodeMdConfigs
    mkClaudecodeMdConfigs
    mkMcpModule
    findToolsByTags
    ;
}
