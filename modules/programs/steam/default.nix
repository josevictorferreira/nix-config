{ lib, ... }:
let
  mkOptions =
    { config, ... }:
    {
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
        default = config.jvf.core.username;
        description = "Username for installing packages to.";
      };
    };

  mkConfig =
    { isDarwin }:
    { config, pkgs, ... }:
    let
      cfg = config.jvf.programs.steam;
    in
    {
      options.jvf.programs.steam = mkOptions { inherit config; };

      config = lib.mkIf cfg.enable (
        if isDarwin then
          {
            # Steam is NixOS-only, no Darwin support
          }
        else
          {
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
          }
      );
    };
in
{
  flake.modules.nixos.programs-steam = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-steam = mkConfig { isDarwin = true; };
}
