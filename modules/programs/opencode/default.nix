{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.opencode;

  aiTools = import ../../common/ai-tools { inherit lib pkgs; };

  mkMdConfigs =
    prefix: attrset:
    lib.mapAttrs' (name: value: {
      name = "${prefix}/${name}.md";
      value = value;
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
    ./mcp.nix
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
    jvf.wrappers.users.${cfg.username}.programs.opencode = {
      packages = [
        shellScriptBin
      ];
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
