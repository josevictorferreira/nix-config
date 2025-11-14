{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.roles.opsDevelopment;
in
{
  imports = [
    ../programs/k9s.nix
    ../services/virtualisation.nix
  ];

  options.jvf.roles.opsDevelopment = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable devops developer tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.k9s.enable = true;
    jvf.services.virtualisation.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.awscli
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.helmfile
      pkgs.podman-compose
    ];
  };
}
