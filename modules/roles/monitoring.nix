{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.jvf.roles.monitoring;
in
{
  imports = [
    ../programs/btop.nix
    ../programs/k9s.nix
  ];

  options.jvf.roles.monitoring.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable administrative tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.btop.enable = true;

    environment.systemPackages = [
      pkgs.htop-vim
      pkgs.ncdu
      pkgs.inetutils
      pkgs.dig
      pkgs.nettools
      pkgs.lsof
      pkgs.nmap
      pkgs.arp-scan
    ];
  };
}
