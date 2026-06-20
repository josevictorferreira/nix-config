# Aspect: programs-forgecode
# Installs ForgeCode AI coding tool with configuration via jvf.home.
# Supports providers, skills, agents, and commands like OpenCode.
_:
let
  mkForgeCodeConfig =
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.programs.forgecode;

      forgeCodePkg = pkgs.rustPlatform.buildRustPackage rec {
        pname = "forgecode";
        version = "0.1.0-dev";

        src = pkgs.fetchFromGitHub {
          owner = "tailcallhq";
          repo = "forgecode";
          rev = "82ae187a3c3a2703e0c408605c20f3aca3368291";
          hash = "sha256-YqMq/Z65v83pDrYmH7K7RD5HLfexziTJ1AKBukNubDA=";
        };

        cargoHash = "sha256-lWXYGlEkE6OXygKwdjmx4MRymXRc6P0PmIg/sk1W4Fw=";

        cargoBuildFlags = [
          "-p"
          "forge_main"
          "--bin"
          "forge"
        ];

        nativeBuildInputs = with pkgs; [
          cmake
          nasm
          perl
          pkg-config
          protobuf
        ];

        buildInputs =
          with pkgs;
          [
            sqlite
          ]
          ++ lib.optionals stdenv.isLinux [
            libxkbcommon
            libx11
            libxext
            libxfixes
            libxcb
            wayland
          ]
          ++ lib.optionals stdenv.isDarwin [
            libiconv
          ];

        PROTOC = "${pkgs.protobuf}/bin/protoc";
        PROTOC_INCLUDE = "${pkgs.protobuf}/include";
        APP_VERSION = version;

        postInstall = ''
          mkdir -p $out/share/zsh/plugins/forgecode
          cp -r shell-plugin/* $out/share/zsh/plugins/forgecode/
        '';

        doCheck = false;

        meta = with lib; {
          description = "forge: AI enabled pair programmer for Claude, GPT, O Series, Grok, Deepseek, Gemini and 300+ models";
          homepage = "https://forgecode.dev";
          license = licenses.mit;
          mainProgram = "forge";
          platforms = platforms.unix;
        };
      };

      # Default providers matching opencode configuration
      defaultProviders = {
        alibaba-coding-plan = {
          id = "alibaba-coding-plan";
          api_key_var = "ALIBABA_CODING_PLAN_API_KEY";
          response_type = "OpenAI";
          url = "https://www.gigis.ai/api/v1/chat/completions";
          models = [
            "qwen3.5-plus"
            "qwen3.6-plus"
            "qwen3-max-2026-01-23"
            "qwen3-coder-next"
            "qwen3-coder-plus"
            "MiniMax-M2.5"
            "glm-5"
            "glm-4.7"
            "kimi-k2.5"
          ];
        };
        kimi-for-coding = {
          id = "kimi-for-coding";
          api_key_var = "KIMI_API_KEY";
          response_type = "OpenAI";
          url = "https://api.kimi.com/coding/v1/chat/completions";
          models = [
            "kimi-k2.6"
            "kimi-k2.5"
          ];
        };
        zai-coding-plan = {
          id = "zai-coding-plan";
          api_key_var = "Z_AI_API_KEY";
          response_type = "OpenAI";
          url = "https://api.z.ai/api/coding/paas/v4/chat/completions";
          models = [
            "glm-5-turbo"
            "glm-5.1"
            "glm-5"
            "glm-4.7"
            "glm-4.7-flash"
          ];
        };
        openrouter = {
          id = "openrouter";
          api_key_var = "OPENROUTER_API_KEY_CODE_AGENT";
          response_type = "OpenAI";
          url = "https://openrouter.ai/api/v1/chat/completions";
          models = [ ];
        };
        nvidia = {
          id = "nvidia";
          api_key_var = "NVIDIA_API_KEY";
          response_type = "OpenAI";
          url = "https://api.nvidia.com/ai/v1/chat/completions";
          models = [ ];
        };
        inception = {
          id = "inception";
          api_key_var = "INCEPTION_API_KEY";
          response_type = "OpenAI";
          url = "https://api.inceptionlabs.ai/v1/chat/completions";
          models = [
            "mercury-2"
          ];
        };
        local = {
          id = "local";
          response_type = "OpenAI";
          url = "http://localhost:11434/v1/chat/completions";
          models = [
            "llama3.2"
            "qwen2.5-coder:14b"
            "mistral-nemo"
            "nemotron-mini"
            "qwen2.5-coder:32b"
            "phi4"
            "deepseek-r1:14b"
            "deepseek-r1:32b"
            "mixtral:8x7b"
          ];
        };
        huggingface = {
          id = "huggingface";
          api_key_var = "HUGGINGFACE_API_KEY";
          response_type = "OpenAI";
          url = "https://api-inference.huggingface.co/v1/chat/completions";
          models = [ ];
        };
      };

      # Merge user providers with defaults
      finalProviders = lib.mapAttrs
        (
          name: defaultProvider:
            if cfg.providers ? ${name} then defaultProvider // cfg.providers.${name} else defaultProvider
        )
        defaultProviders;

      # Forge inline TOML providers only support model URLs. Use provider.json
      # instead so these custom providers can keep their static model lists.
      mkProviderModel = model: {
        id = model;
        name = model;
      };

      providersJson = lib.mapAttrsToList
        (
          _: v:
            {
              inherit (v) id response_type url;
              auth_methods = [ "api_key" ];
              models = map mkProviderModel v.models;
            }
            // lib.optionalAttrs (v ? api_key_var && v.api_key_var != null) {
              api_key_vars = v.api_key_var;
            }
        )
        finalProviders;

      # Generate TOML content for Forge settings. Provider definitions live in
      # provider.json because Forge TOML provider entries cannot hold static models.
      forgeTomlData = cfg.settings;

      forgeTomlFile = (pkgs.formats.toml { }).generate "forge.toml" forgeTomlData;

      providerJsonFile = (pkgs.formats.json { }).generate "provider.json" providersJson;

      # Combine Forge TOML with optional MCP TOML without forcing an eval-time build.
      fullTomlFile =
        if mcpTomlContent != "" then
          pkgs.runCommand "forge.toml" { } ''
            cat ${forgeTomlFile} > "$out"
            echo "" >> "$out"
            cat ${pkgs.writeText "mcp.toml" mcpTomlContent} >> "$out"
          ''
        else
          forgeTomlFile;

      # Generate command files (markdown with YAML frontmatter)
      mkCommandFile =
        name: value:
        let
          isStructured = builtins.isAttrs value && value ? prompt;
          prompt =
            if isStructured then
              value.prompt
            else if builtins.isString value then
              value
            else
              "";
          description = if isStructured then value.description or "" else "";
          model = if isStructured then value.model or "" else "";
          agent = if isStructured then value.agent or "" else "";
          temperature = if isStructured then value.temperature or null else null;
          tools = if isStructured then value.tools or [ ] else [ ];

          yamlLines = [
            "---"
          ]
          ++ [ "name: \"${name}\"" ]
          ++ lib.optional (description != "") "description: \"${description}\""
          ++ lib.optional (model != "") "model: \"${model}\""
          ++ lib.optional (agent != "") "agent: \"${agent}\""
          ++ lib.optional (temperature != null) "temperature: ${toString temperature}"
          ++ lib.optional (tools != [ ]) "tools: [${lib.concatStringsSep ", " (map (t: "\"${t}\"") tools)}]"
          ++ [ "---" ];

          yamlHeader = lib.concatStringsSep "\n" yamlLines;
        in
        yamlHeader + "\n\n" + prompt;

      # Generate agent files (markdown with YAML frontmatter)
      mkAgentFile =
        name: value:
        let
          isStructured = builtins.isAttrs value && value ? prompt;
          prompt =
            if isStructured then
              value.prompt
            else if builtins.isString value then
              value
            else
              "";
          description = if isStructured then value.description or "" else "";
          model = if isStructured then value.model or "" else "";
          mode = if isStructured then value.mode or "primary" else "primary";
          temperature = if isStructured then value.temperature or null else null;
          permission = if isStructured then value.permission or { } else { };
          tools = if isStructured then value.tools or [ ] else [ ];
          disabledTools = if isStructured then value.disabledTools or [ ] else [ ];

          formatPermission =
            key: perm:
            if builtins.isString perm then
              "  ${key}: \"${perm}\""
            else if builtins.isAttrs perm then
              "  ${key}:\n" + lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "    ${k}: \"${v}\"") perm)
            else
              "";

          yamlLines =
            [ "---" ]
            ++ [ "name: \"${name}\"" ]
            ++ [ "type: agent" ]
            ++ lib.optional (description != "") "description: \"${description}\""
            ++ lib.optional (model != "") "model: \"${model}\""
            ++ lib.optional (mode != "primary") "mode: \"${mode}\""
            ++ lib.optional (temperature != null) "temperature: ${toString temperature}"
            ++ lib.optional (permission != { }) "permission:\n"
            +
            lib.concatStringsSep "\n" (lib.mapAttrsToList formatPermission permission)
            ++ lib.optional (tools != [ ]) "tools:\n"
            +
            lib.concatStringsSep "\n" (map (t: "  - \"${t}\"") tools)
            ++ lib.optional (disabledTools != [ ]) "disabled_tools:\n"
            + lib.concatStringsSep "\n" (map (t: "  - \"${t}\"") disabledTools) ++ [ "---" ];

          yamlHeader = lib.concatStringsSep "\n" yamlLines;
        in
        yamlHeader + "\n\n" + prompt;

      # Generate skill configs using ai-tools lib
      skillConfigs = if cfg.skills != { } then inputs.lib.aiTools.mkSkillsConfigs cfg.skills else { };

      # Build skills directory using linkFarm
      skillsDir =
        if skillConfigs != { } then
          pkgs.linkFarm "forgecode-skills"
            (
              lib.mapAttrsToList
                (
                  fileName: fileValue:
                    let
                      filePath =
                        if lib.isDerivation fileValue then
                          fileValue
                        else if builtins.isString fileValue then
                          pkgs.writeText "forgecode-skill-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue
                        else
                          fileValue;
                    in
                    {
                      name = fileName;
                      path = filePath;
                    }
                )
                skillConfigs
            )
        else
          null;

      # Generate MCP configs
      mkMcpToml =
        mcps:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList
            (
              name: cfg:
              let
                command =
                  if cfg ? command then
                    if builtins.isList cfg.command then builtins.head cfg.command else cfg.command
                  else
                    "";
                args = cfg.args or [ ];
                env = cfg.env or { };

                argsStr =
                  if args != [ ] then "args = [" + lib.concatStringsSep ", " (map (a: "\"${a}\"") args) + "]" else "";

                envStr =
                  if env != { } then
                    "env = { " + lib.concatStringsSep ", " (lib.mapAttrsToList (k: v: "${k} = \"${v}\"") env) + " }"
                  else
                    "";
              in
              "[mcp.\"${name}\"]\n"
              + "command = \"${command}\"\n"
              + lib.optionalString (argsStr != "") (argsStr + "\n")
              + lib.optionalString (envStr != "") (envStr + "\n")
            )
            mcps
        );

      mcpTomlContent = if cfg.mcps != { } then mkMcpToml cfg.mcps else "";

      # Build ForgeCode config directory as a derivation for jvf.home
      forgeConfigFiles = {
        ".forge.toml" = fullTomlFile;
        "provider.json" = providerJsonFile;
      }
      // lib.mapAttrs'
        (name: value: {
          name = "commands/${name}.md";
          value = mkCommandFile name value;
        })
        cfg.commands
      // lib.mapAttrs'
        (name: value: {
          name = "agents/${name}.md";
          value = mkAgentFile name value;
        })
        cfg.agents;

      forgeConfigDir = pkgs.linkFarm "forgecode-config" (
        lib.mapAttrsToList
          (
            fileName: fileValue:
              let
                filePath =
                  if lib.isDerivation fileValue then
                    fileValue
                  else if builtins.isString fileValue then
                    pkgs.writeText "forgecode-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue
                  else
                    fileValue;
              in
              {
                name = fileName;
                path = filePath;
              }
          )
          forgeConfigFiles
      );

    in
    {
      imports = [ ./options.nix ];

      config = {
        jvf.programs.forgecode.package = lib.mkDefault forgeCodePkg;

        users.users."${cfg.username}".packages = [
          (lib.mkDefault forgeCodePkg)
          pkgs.fzf
          pkgs.bat
          pkgs.fd
        ];

        # Zsh plugin integration
        programs.zsh.interactiveShellInit = lib.mkAfter ''
          # ForgeCode Zsh Plugin
          if [ -f ${forgeCodePkg}/share/zsh/plugins/forgecode/forge.plugin.zsh ]; then
            source ${forgeCodePkg}/share/zsh/plugins/forgecode/forge.plugin.zsh
          fi
        '';

        # Materialize ForgeCode configuration using jvf.home
        jvf.home.users.${cfg.username}.items = lib.mkMerge [
          # ForgeCode config directory at ~/.forge with preserve for runtime data
          {
            ".forge" = {
              kind = "dir";
              mode = "copy";
              source = forgeConfigDir;
              preserve = [
                "cache"
                ".credentials.json"
                ".forge_history"
                "logs"
                "snapshots"
              ];
            };
          }

          # Skills at ~/.agents/skills/* (co-installed with OpenCode)
          (lib.optionalAttrs (skillsDir != null) {
            ".agents/skills" = {
              kind = "dir";
              mode = "copy";
              source = skillsDir;
            };
          })
        ];
      };
    };
in
{
  flake.modules.nixos.programs-forgecode = mkForgeCodeConfig;
  flake.modules.darwin.programs-forgecode = mkForgeCodeConfig;
}
