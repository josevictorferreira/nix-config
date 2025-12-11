{
  lib,
  ...
}:

let
  toClaudeMarkdownPrompt =
    value:
    if builtins.isAttrs value && value ? prompt then
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
      builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

  toOpencodeMarkdownPrompt =
    value:
    if builtins.isAttrs value && value ? prompt then
      let
        yamlHeader = ''
          ---
          name: "${value.name or "unknown"}"
          description: "${value.description or ""}"
          ${if (value ? tools && value.tools != [ ]) then "tools:" else ""}
          ${lib.optionalString (value ? tools && value.tools != [ ]) (
            lib.concatMapStringsSep "\n" (tool: "  ${lib.toLower tool}*: true") value.tools
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
          lib.mapAttrs' (refName: refContent: {
            name = "skills/${skillName}/references/${refName}.md";
            value = refContent;
          }) skill.references
        else
          { };

      # Script files
      scripts =
        if skill ? scripts && skill.scripts != { } then
          lib.mapAttrs' (scriptName: scriptContent: {
            name = "skills/${skillName}/scripts/${scriptName}";
            value = scriptContent;
          }) skill.scripts
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
    prefix: attrset:
    lib.mapAttrs' (name: value: {
      name = "${prefix}/${name}.md";
      value = toOpencodeMarkdownPrompt value;
    }) attrset;

  mkClaudecodeMdConfigs =
    prefix: attrset:
    lib.mapAttrs' (name: value: {
      name = "${prefix}/${name}.md";
      value = toClaudeMarkdownPrompt value;
    }) attrset;
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
    ;
}
