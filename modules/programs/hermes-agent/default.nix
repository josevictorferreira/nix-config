# Aspect: programs-hermes-agent
# Defines jvf.programs.hermes-agent options for Nous Research Hermes Agent.
# Installs hermes-agent via the official install script on first use.
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.hermes-agent;
      username = cfg.username;
    in
    {
      imports = [ ./options.nix ];

      config = {
        # Set default username from jvf.core
        jvf.programs.hermes-agent.username = lib.mkDefault config.jvf.core.username;

        jvf.wrappers.users.${username}.programs.hermes.packages = [
          # hermes-agent wrapper - runs install script on first use
          (pkgs.writeShellScriptBin "hermes" ''
            set -euo pipefail

            HERMES_HOME="$HOME/.hermes"
            HERMES_BIN="$HERMES_HOME/hermes-agent/venv/bin/hermes"

            # Install if not present
            if [ ! -x "$HERMES_BIN" ]; then
              echo "Installing hermes-agent..."
              curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash -s -- --skip-setup
            fi

            exec "$HERMES_BIN" "$@"
          '')
          # hermes-gateway wrapper for messaging platforms
          (pkgs.writeShellScriptBin "hermes-gateway" ''
            set -euo pipefail

            HERMES_HOME="$HOME/.hermes"
            HERMES_BIN="$HERMES_HOME/hermes-agent/venv/bin/hermes"

            # Install if not present
            if [ ! -x "$HERMES_BIN" ]; then
              echo "Installing hermes-agent..."
              curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash -s -- --skip-setup
            fi

            exec "$HERMES_BIN" gateway "$@"
          '')
        ];

        # Migrate config to jvf.home (Phase 3: configPath + preserveFiles)
        # The .hermes dir is managed by the install script; we just preserve it
        jvf.home.users.${username}.items.".hermes" = {
          kind = "dir";
          mode = "seed";
          source = pkgs.runCommand "hermes-empty-dir" { } "mkdir -p $out";
        };
      };
    };
in
{
  flake.modules.nixos.programs-hermes-agent = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-hermes-agent = mkConfig { isDarwin = true; };
}
