{ config
, lib
, system
, ...
}:

let
  cfg = config.jvf.system.firewall;
  isDarwin = builtins.match ".*-darwin" system != null;
in
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
}
