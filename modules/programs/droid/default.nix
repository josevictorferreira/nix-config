# Aspect: programs-droid
{ ... }:
let
  # Import default settings generator
  mkDefaultSettings = import ./_/settings.nix;

  mkDroidConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.programs.droid;
      isLinux = !isDarwin;

      droidFHS =
        if isLinux then
          pkgs.buildFHSEnv
            {
              name = "droid-fhs";
              targetPkgs = pkgs: [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.openssl
                pkgs.curl
                pkgs.ripgrep
                pkgs.coreutils
              ];
              profile = ''
                export TMPDIR="''${TMPDIR:-$HOME/.cache/factory-tmp}"
                mkdir -p "$TMPDIR"
              '';
              runScript = "${pkgs.writeShellScript "droid-runner" ''
              exec "$HOME/.local/bin/droid" "$@"
            ''}";
            }
        else
          null;

      shellScriptBin = pkgs.writeShellScriptBin "droid" ''
        set -euo pipefail

        INSTALL_URL="https://app.factory.ai/cli"
        LOCAL_BIN="$HOME/.local/bin"
        LOCAL_DROID="$LOCAL_BIN/droid"
        FACTORY_BIN_DIR="$HOME/.factory/bin"

        mkdir -p "$FACTORY_BIN_DIR"
        if [ ! -e "$FACTORY_BIN_DIR/rg" ]; then
          ln -sf "${pkgs.ripgrep}/bin/rg" "$FACTORY_BIN_DIR/rg"
        fi

        if [ ! -x "$LOCAL_DROID" ]; then
          mkdir -p "$LOCAL_BIN"
          PATH="$FACTORY_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
        fi

        ${
          if isLinux then
            ''
              exec "${droidFHS}/bin/droid-fhs" "$@"
            ''
          else
            ''
              exec "$LOCAL_DROID" "$@"
            ''
        }
      '';
    in
    {
      imports = [ ./options.nix ];

      config = {
        # Set default settings from imported config generator
        jvf.programs.droid.settings = lib.mkDefault (mkDefaultSettings { inherit (cfg) mcps; }).settings;

        jvf.wrappers.users.${cfg.username}.programs.droid = {
          packages = [
            shellScriptBin
          ];
          configPath = ".factory";
          preserveFiles = [
            "sounds"
            "temp"
            "sessions"
            "logs"
            "mcp.json"
            "certs"
            "background-processes.json"
            "auth.json"
          ];
          configs = lib.mkMerge [
            (inputs.lib.aiTools.mkClaudecodeMdConfigs config.jvf.aiTools.mcp "droids" cfg.agents)
            (inputs.lib.aiTools.mkClaudecodeMdConfigs config.jvf.aiTools.mcp "commands" cfg.commands)
            (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
            { "settings.json" = cfg.settings; }
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-droid = mkDroidConfig { isDarwin = false; };
  flake.modules.darwin.programs-droid = mkDroidConfig { isDarwin = true; };
}
