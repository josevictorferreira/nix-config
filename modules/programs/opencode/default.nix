{ lib
, pkgs
, config
, username
, system
, ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.opencode;

  aiTools = import ../../common/ai-tools { inherit lib pkgs system; };
  isDarwin = builtins.match ".*-darwin" system != null;

  # Convert ai-tools to markdown format for opencode
  # Handles both structured format (Phase 2/3) and legacy markdown strings
  mkMdConfigs =
    prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = aiTools.lib.toOpencodeMarkdownPrompt value;
      })
      attrset;

  # Extract MCP configs for opencode from centralized ai-tools mcp
  mcpConfigs = lib.mapAttrs (name: cfg: cfg.opencode or { }) aiTools.mcp;

  # Extract all tools from agents and commands for disable settings
  allTools = lib.unique (aiTools.lib.extractTools (aiTools.agents // aiTools.commands));
  toolDisableSettings = aiTools.lib.mkToolDisableSettings allTools;

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

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.config/opencode/config.json";
    };
  };

  config = lib.mkIf cfg.enable {
    # Merge centralized MCP configs into settings
    jvf.programs.opencode.settings = lib.mkMerge [
      {
        mcp = mcpConfigs;
        tools = toolDisableSettings;
      }
    ];

    jvf.wrappers.users.${cfg.username}.programs.opencode = {
      packages = [
      ]
      ++ lib.optional isDarwin pkgs.opencode
      ++ lib.optional (!isDarwin) shellScriptBin;
      configs = lib.mkMerge [
        (mkMdConfigs "agent" aiTools.agents)
        (mkMdConfigs "command" aiTools.commands)
        {
          "config.json" = cfg.settings;
        }
      ];
    };
  };
}
