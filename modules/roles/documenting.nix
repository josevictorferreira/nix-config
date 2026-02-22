# Aspect: roles-documenting
# Bundles document viewing and editing tools (obsidian, libreoffice, zathura, etc).
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.roles.documenting = {
        enable = lib.mkEnableOption "documenting tools bundle";

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
      cfg = config.jvf.roles.documenting;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        users.users."${cfg.username}".packages = [
          pkgs.font-manager
          pkgs.obsidian
          pkgs.koreader
          pkgs.libreoffice-still
          pkgs.zathura
        ];
      };
    };
in
{
  flake.modules.nixos.roles-documenting = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-documenting = mkConfig { isDarwin = true; };
}
