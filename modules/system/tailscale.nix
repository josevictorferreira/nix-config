# Aspect: system-tailscale
# Defines jvf.system.tailscale options and platform-specific tailscale config.
# NixOS: services.tailscale with routing features and firewall integration.
# Darwin: services.tailscale.enable.
{ lib, ... }:
let
  mkTailscaleOptions =
    { config, lib, ... }:
    {
      options.jvf.system.tailscale = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Tailscale VPN.";
        };
        authKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the Tailscale auth key file.";
        };
      };
    };

  tailscaleModule =
    { config, pkgs, ... }:
    let
      cfg = config.jvf.system.tailscale;
    in
    {
      imports = [ mkTailscaleOptions ];

      config = lib.mkIf cfg.enable {
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          authKeyFile = cfg.authKeyFile;
          extraSetFlags = [ "--accept-dns=true" ];
        };

        networking.firewall = {
          trustedInterfaces = [ "tailscale0" ];
          allowedUDPPorts = [ config.services.tailscale.port ];
        };
      };
    };
in
{
  flake.modules.nixos.system-tailscale = tailscaleModule;
}
