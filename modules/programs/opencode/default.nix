{ lib
, pkgs
, config
, username
, system
, inputs
, ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.opencode;
  isDarwin = builtins.match ".*-darwin" system != null;

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
    ./plugins.nix
  ];

  options.jvf.programs.opencode = {
    enable = lib.mkEnableOption "Install opencode and write per-user ~/.config/opencode/config.json";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    baseRules = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "A set of base rules to apply to the OpenCode configuration.";
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Agents to install into the configuration (string prompts or structured objects)";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
      default = { };
      description = "Skills to install into the configuration (string prompts or structured objects)";
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

    ohMyOpenCodeSettings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.config/opencode/oh-my-opencode.json";
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.config/opencode/config.json";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.settings = {
      theme = lib.mkDefault "one-dark";
      mcp = lib.mkDefault cfg.mcps;
      disabled_providers = lib.mkDefault [
        "opencode"
        "copilot"
        "github-copilot"
        "github-copilot-enterprise"
        "copilot-enterprise"
        "github-models"
        "minimax-cn"
      ];

      tools = lib.mkDefault {
        "context7*" = true;
        "ck*" = false;
        "chrome-devtools*" = false;
        "playwriter*" = false;
        "grep_app*" = true;
        "mcp-nixos*" = false;
        "shadcn*" = false;
        "websearch*" = false;
      };

      watcher = {
        ignore = [ "node_modules/**" "dist/**" ".git/**" "build/**" ".bundle/**" "__pycache__/**" ".ck/**" ];
      };

      model = "zai/GLM-4.7";
      small_model = "openrouter/openai/gpt-oss-120b";
    };

    jvf.wrappers.users.${cfg.username}.programs.opencode = {
      preserveFiles = [
        "antigravity-accounts.json"
        "node_modules"
        "dcp.jsonc"
        "package.json"
        "bun.lock"
      ];
      packages = [
        pkgs.bun
      ]
      ++ lib.optional isDarwin pkgs.opencode
      ++ lib.optional (!isDarwin) shellScriptBin;
      configs = lib.mkMerge [
        (inputs.lib.aiTools.mkOpencodeMdConfigs config.jvf.aiTools.mcp "agent" cfg.agents)
        (inputs.lib.aiTools.mkOpencodeMdConfigs config.jvf.aiTools.mcp "command" cfg.commands)
        (inputs.lib.aiTools.mkSkillConfigs cfg.skills)
        {
          "AGENTS.md" = cfg.baseRules;
          "opencode.json" = cfg.settings;
          "oh-my-opencode.json" = cfg.ohMyOpenCodeSettings;
          "antigravity.json" = {
            pid_offset_enabled = true;
          };
        }
      ];
    };
  };
}
