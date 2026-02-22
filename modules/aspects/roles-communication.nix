# Aspect: roles-communication
# Bundles communication tools (discord, slack, telegram, weechat).
# Enables weechat program aspect with matrix support.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.roles.communication = {
        enable = lib.mkEnableOption "communication tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for installing packages to.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.communication;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs.weechat = {
          enable = true;
          matrix.enable = true;
        };

        users.users."${cfg.username}".packages = [
          pkgs.discord
          pkgs.brave
        ];
      };
    };
in
{
  flake.modules.nixos.roles-communication = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-communication = mkConfig { isDarwin = true; };
}
