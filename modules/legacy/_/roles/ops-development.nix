{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.jvf.roles.opsDevelopment;
in
{
  # Program modules migrated to dendritic aspects (Phase 3)
  # - programs-k9s now in hosts/nixos-desktop.nix aspects list

  options.jvf.roles.opsDevelopment = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable devops developer tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.k9s.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.awscli
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.helmfile
    ];
  };
}
