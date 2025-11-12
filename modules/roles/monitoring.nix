{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.jvf.roles.monitoring;
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
