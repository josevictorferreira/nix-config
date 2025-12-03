{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.programs.steam;
in
{
  options.jvf.programs.steam = {
    enable = lib.mkEnableOption "Steam gaming platform" // {
      description = ''
        Whether to enable Steam gaming platform.
        Configures Steam with firewall rules for:
        - Remote Play
        - Dedicated servers
        - Local network game transfers
      '';
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.variables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    };

    users.users."${cfg.username}".packages = [
      pkgs.protonup-qt
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
}
