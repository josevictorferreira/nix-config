{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.roles.opsDevelopment;
in
{
  imports = [
    ../programs/k9s.nix
  ];

  options.jvf.roles.opsDevelopment.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable devops developer tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.k9s.enable = true;

    environment.systemPackages = [
      pkgs.awscli
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.helmfile
    ];
  };
}
