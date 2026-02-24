# Aspect: roles-monitoring
# Monitoring and admin tools.
# NixOS: btop + disk/network/system utilities + gparted.
# Darwin: btop + disk/network/system utilities (no gparted).
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.monitoring = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  commonPackages = pkgs: [
    pkgs.baobab
    pkgs.btop
    pkgs.duf
    pkgs.inxi
    pkgs.mtr
    pkgs.lsof
    pkgs.ncdu
    pkgs.htop-vim
    pkgs.inetutils
    pkgs.dig
    pkgs.nettools
    pkgs.nmap
    pkgs.arp-scan
    pkgs.pciutils
  ];

  nixosModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.monitoring;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-btop
      ]);

      config = {
        users.users."${cfg.username}".packages = (commonPackages pkgs) ++ [ pkgs.gparted ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.monitoring;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        programs-btop
      ]);

      config = {
        users.users."${cfg.username}".packages = commonPackages pkgs;
      };
    };
in
{
  flake.modules.nixos.roles-monitoring = nixosModule;
  flake.modules.darwin.roles-monitoring = darwinModule;
}
