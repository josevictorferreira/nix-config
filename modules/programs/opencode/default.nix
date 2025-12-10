{
  lib,
  pkgs,
  config,
  username,
  system,
  ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.opencode;
  isDarwin = builtins.match ".*-darwin" system != null;

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

  mkMdConfigs =
    prefix: attrset:
    lib.mapAttrs' (name: value: {
      name = "${prefix}/${name}.md";
      value = toOpencodeMarkdownPrompt value;
    }) attrset;

  openCodeFHS = pkgs.buildFHSEnv {
    name = "opencode-fhs";
    targetPkgs =
      pkgs: with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        ripgrep
        coreutils
      ];
    profile = ''
      export TMPDIR="''${TMPDIR:-$HOME/.cache/opencode-tmp}"
      mkdir -p "$TMPDIR"
    '';
    runScript = "${pkgs.writeShellScript "opencode-runner" ''
      exec "$HOME/.opencode/bin/opencode" "$@"
    ''}";
  };

  shellScriptBin = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    INSTALL_URL="https://opencode.ai/install"
    OPENCODE_BIN_DIR="$HOME/.opencode/bin"

    if [ ! -x "$OPENCODE_BIN_DIR" ]; then
      mkdir -p "$OPENCODE_BIN_DIR"
      PATH="$OPENCODE_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
    fi

    exec "${openCodeFHS}/bin/opencode-fhs" "$@"
  '';
in
{
  imports = [
    ./formatters.nix
    ./lsp.nix
    ./provider.nix
    ./permission.nix
  ];

  options.jvf.programs.opencode = {
    enable = lib.mkEnableOption "Install opencode and write per-user ~/.config/opencode/config.json";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Agents to install into the configuration (string prompts or structured objects)";
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Commands to install into the configuration (string prompts or structured objects)";
    };

    mcps = lib.mkOption {
      type = lib.types.attrsOf json.type;
      default = { };
      description = "MCP tools to install into the configuration (structured objects)";
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.config/opencode/config.json";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.opencode = {
      packages = [
      ]
      ++ lib.optional isDarwin pkgs.opencode
      ++ lib.optional (!isDarwin) shellScriptBin;
      configs = lib.mkMerge [
        (mkMdConfigs "agent" cfg.agents)
        (mkMdConfigs "command" cfg.commands)
        {
          "config.json" = (
            cfg.settings
            // {
              mcp = cfg.mcps;
            }
          );
        }
      ];
    };
  };
}
