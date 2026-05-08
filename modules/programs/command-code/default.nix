# Aspect: programs-command-code
# Installs Command Code CLI and materializes its user configuration.
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.programs.command-code;
      json = pkgs.formats.json { };

      npmPrefix = "$HOME/.npm-global";
      commandCodePackage = "command-code@latest";

      commandCodeFHS =
        if !isDarwin then
          pkgs.buildFHSEnv
            {
              name = "command-code-fhs";
              targetPkgs = pkgs: [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.openssl
                pkgs.nodejs_22
                pkgs.coreutils
              ];
              profile = ''
                export TMPDIR="''${TMPDIR:-$HOME/.cache/command-code-tmp}"
                mkdir -p "$TMPDIR"
              '';
              runScript = "${pkgs.writeShellScript "command-code-runner" ''
              exec "$HOME/.npm-global/bin/cmd" "$@"
            ''}";
            }
        else
          null;

      commandCodeWrapper = pkgs.writeShellScriptBin "cmd" ''
        set -euo pipefail

        export PATH="${lib.makeBinPath [ pkgs.nodejs_22 ]}:$PATH"
        NPM_PREFIX="${npmPrefix}"
        NPM_BIN="$NPM_PREFIX/bin"
        VERSION_FILE="$NPM_PREFIX/.command-code-version"

        mkdir -p "$NPM_PREFIX"
        ${pkgs.nodejs_22}/bin/npm config set prefix "$NPM_PREFIX" 2>/dev/null || true

        LATEST_VERSION=$(${pkgs.nodejs_22}/bin/npm view "${commandCodePackage}" version 2>/dev/null || echo "unknown")
        CURRENT_VERSION=""
        if [ -f "$VERSION_FILE" ]; then
          CURRENT_VERSION=$(cat "$VERSION_FILE")
        fi

        if [ ! -x "$NPM_BIN/cmd" ] || [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
          echo "Installing/updating command-code (${commandCodePackage})..."
          echo "  Current: ''${CURRENT_VERSION:-not installed}"
          echo "  Latest:  $LATEST_VERSION"
          ${pkgs.nodejs_22}/bin/npm install -g "${commandCodePackage}"
          echo "$LATEST_VERSION" > "$VERSION_FILE"
        fi

        export PATH="$NPM_BIN:$PATH"
        ${
          if !isDarwin then
            ''
              exec "${commandCodeFHS}/bin/command-code-fhs" "$@"
            ''
          else
            ''
              exec "$NPM_BIN/cmd" "$@"
            ''
        }
      '';

      toCommandCodeMarkdown =
        value:
        if builtins.isAttrs value && value ? prompt then
          let
            explicitTools = value.tools or (value.allowed-tools or [ ]);
            toolsValue =
              if explicitTools == [ ] then "none" else ''"${lib.concatStringsSep ", " explicitTools}"'';
            headerLines = [
              ''name: "${value.name or "unknown"}"''
              "description: ${builtins.toJSON (value.description or "")}"
              "tools: ${toolsValue}"
            ];
            yamlHeader = "---\n" + lib.concatStringsSep "\n" headerLines + "\n---\n\n";
          in
          yamlHeader + value.prompt
        else
          builtins.trace "WARNING: Using deprecated plain Markdown string format. Please migrate to structured format with mkAgent/mkCommand." value;

      mkCommandCodeMdConfigs =
        prefix: attrset:
        lib.mapAttrs'
          (name: value: {
            name = "${prefix}/${name}.md";
            value = toCommandCodeMarkdown value;
          })
          attrset;

      normalizeMcp =
        mcpCfg:
        let
          mcp = inputs.lib.aiTools.transformMcpOptions "command-code" mcpCfg;
          rawTransport = mcp.transport or (mcp.type or (if mcp ? url then "http" else "stdio"));
          transport = if rawTransport == "local" then "stdio" else rawTransport;
        in
        (builtins.removeAttrs mcp [ "type" ])
        // {
          inherit transport;
          enabled = mcp.enabled or true;
        };

      commandCodeMcps = lib.mapAttrs (_name: normalizeMcp) cfg.mcps;

      commandCodeConfigs =
        (mkCommandCodeMdConfigs "agents" cfg.agents)
        // (inputs.lib.aiTools.mkClaudecodeMdConfigs "commands" cfg.commands)
        // (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
        // (lib.optionalAttrs (cfg.baseRules != "") {
          "AGENTS.md" = cfg.baseRules;
        })
        // (lib.optionalAttrs (cfg.settings != { }) {
          "config.json" = cfg.settings;
        })
        // (lib.optionalAttrs (commandCodeMcps != { }) {
          "mcp.json" = {
            mcpServers = commandCodeMcps;
          };
        });

      commandCodeConfigDir = pkgs.linkFarm "command-code-config" (
        lib.mapAttrsToList
          (
            fileName: fileValue:
              let
                filePath =
                  if lib.isDerivation fileValue then
                    fileValue
                  else if builtins.isString fileValue then
                    pkgs.writeText "command-code-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue
                  else if builtins.isAttrs fileValue then
                    pkgs.writeText "command-code-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}"
                      (
                        inputs.lib.generators.toFileFormatStr (lib.last (lib.splitString "." fileName)) fileValue
                      )
                  else
                    fileValue;
              in
              {
                name = fileName;
                path = filePath;
              }
          )
          commandCodeConfigs
      );
    in
    {
      options.jvf.programs.command-code = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing Command Code to.";
        };

        baseRules = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "AGENTS.md instructions for Command Code.";
        };

        agents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Command Code custom agents to install.";
        };

        commands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Command Code custom slash commands to install.";
        };

        mcps = lib.mkOption {
          type = lib.types.attrsOf json.type;
          default = { };
          description = "Command Code MCP servers to install.";
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Command Code skills to install.";
        };

        settings = lib.mkOption {
          inherit (json) type;
          default = { };
          description = "Settings written to ~/.commandcode/config.json.";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.cmd.packages = [
          commandCodeWrapper
        ];

        jvf.home.users.${cfg.username}.items.".commandcode" = {
          kind = "dir";
          mode = "copy";
          source = commandCodeConfigDir;
          preserve = [
            "auth.json"
            "config.local.json"
            "config.staging.json"
            "projects"
            "logs"
            "cache"
            "taste"
            "sessions"
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-command-code = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-command-code = mkConfig { isDarwin = true; };
}
