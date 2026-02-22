# Aspect: system-firewall
# Defines jvf.system.firewall options and platform-specific firewall config.
# NixOS: networking.firewall with configurable TCP/UDP ports.
# Darwin: empty config (firewall managed by macOS).
{ ... }:
let
  mkFirewallOptions =
    { lib, ... }:
    {
      options.jvf.system.firewall = {
        enable = lib.mkEnableOption "system firewall configuration" // {
          description = ''
            Whether to enable system firewall configuration.
            Provides basic ingress filtering while allowing useful services.
          '';
        };

        allowedTCPPorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [
            8000
            8188
          ];
          description = "List of allowed TCP ports.";
        };

        allowedUDPPorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ 8188 ];
          description = "List of allowed UDP ports.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.firewall;
    in
    {
      imports = [ mkFirewallOptions ];

      config = lib.mkIf cfg.enable (
        if (!isDarwin) then
          {
            networking.firewall = {
              enable = true;
              allowedTCPPorts = cfg.allowedTCPPorts;
              allowedUDPPorts = cfg.allowedUDPPorts;
            };
          }
        else
          { }
      );
    };
in
{
  flake.modules.nixos.system-firewall = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-firewall = mkConfig { isDarwin = true; };
}
