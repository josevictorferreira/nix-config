# Aspect: programs-openclaw
# Defines jvf.programs.openclaw options and platform-specific node config.
_:
let
  mkOpenClawOptions =
    { config
    , lib
    , pkgs
    , ...
    }:
    {
      options.jvf.programs.openclaw = {
        enableNode = lib.mkEnableOption "OpenClaw Node Host";

        gatewayHost = lib.mkOption {
          type = lib.types.str;
          default = "100.96.42.22"; # openclaw-nix-2 (Tailscale)
          description = "IP or hostname of the OpenClaw Gateway";
        };

        gatewayPort = lib.mkOption {
          type = lib.types.port;
          default = 18789;
          description = "Port of the OpenClaw Gateway";
        };

        displayName = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.host;
          description = "Display name for this node in the gateway";
        };

        package = lib.mkPackageOption pkgs "openclaw" { };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.openclaw;
    in
    {
      imports = [ mkOpenClawOptions ];

      config = lib.mkIf cfg.enableNode {
        environment.systemPackages = [ cfg.package ];

        nixpkgs.config.permittedInsecurePackages = [
          cfg.package.name
        ];

        # Secret management for the gateway token
        sops.secrets.openclaw_gateway_token = {
          owner = config.jvf.core.username;
        };

        systemd.services.openclaw-node = lib.mkIf (!isDarwin) {
          description = "OpenClaw Node Host";
          after = [ "network.target" "tailscale.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${cfg.package}/bin/openclaw node run --host ${cfg.gatewayHost} --port ${toString cfg.gatewayPort} --display-name ${cfg.displayName}";
            Restart = "always";
            RestartSec = "10s";
            # Load OPENCLAW_GATEWAY_TOKEN from sops secret
            EnvironmentFile = config.sops.secrets.openclaw_gateway_token.path;
            User = config.jvf.core.username;
          };
          environment = {
            HOME = "/home/${config.jvf.core.username}";
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-openclaw = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-openclaw = mkConfig { isDarwin = true; };
}
