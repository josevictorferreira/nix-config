# Aspect: roles-ops-development
# Bundles DevOps tools (k9s, kubectl, helm, awscli).
# Imports k9s program aspect.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.opsDevelopment = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.opsDevelopment;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-k9s
      ]);

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.awscli
          pkgs.kubectl
          pkgs.kubernetes-helm
          pkgs.helmfile
        ];
      };
    };

  darwinModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.opsDevelopment;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        programs-k9s
      ]);

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.awscli
          pkgs.kubectl
          pkgs.kubernetes-helm
          pkgs.helmfile
        ];
      };
    };
in
{
  flake.modules.nixos.roles-ops-development = nixosModule;
  flake.modules.darwin.roles-ops-development = darwinModule;
}
