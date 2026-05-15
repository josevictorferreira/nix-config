# Aspect: system-firewall
# Defines jvf.system.firewall options and platform-specific firewall config.
# NixOS: networking.firewall with configurable TCP/UDP ports.
# Darwin: empty config (firewall managed by macOS).
_:
let
  mkFirewallOptions =
    { lib, ... }:
    {
      options.jvf.system.firewall = {
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

  nixosModule = { config, ... }:
    let
      cfg = config.jvf.system.firewall;
    in
    {
      imports = [ mkFirewallOptions ];

      config = {
            networking.firewall = {
              enable = true;
              inherit (cfg) allowedTCPPorts;
              inherit (cfg) allowedUDPPorts;
            };
          };
    };
in
{
  flake.modules.nixos.system-firewall = nixosModule;
}
