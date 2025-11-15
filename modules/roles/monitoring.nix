{
  config,
  lib,
  pkgs,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.roles.monitoring;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports = [
    ../programs/btop.nix
    ../programs/k9s.nix
  ];

  options.jvf.roles.monitoring = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable administrative tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.btop.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.baobab # disk usage analyzer
      pkgs.btop # system monitor (via jvf.programs)
      pkgs.duf # disk usage/free utility
      pkgs.inxi # system information tool
      pkgs.mtr # network diagnostic
      pkgs.lsof # list open files
      pkgs.ncdu # NCurses Disk Usage
      pkgs.htop-vim # interactive process viewer
      pkgs.inetutils # networking utilities
      pkgs.dig # DNS lookup
      pkgs.nettools # network configuration tools
      pkgs.nmap # network scanner
      pkgs.arp-scan # ARP scanner
      pkgs.cpufrequtils
      pkgs.pciutils
    ]
    ++ (lib.optional (!isDarwin) pkgs.gparted);
  };
}
