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
  options.jvf.roles.documenting.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable documenting viewing and editing tools.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.font-manager
      pkgs.obsidian
      pkgs.koreader
      pkgs.libreoffice
    ];
  };
}
