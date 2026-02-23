# Aspect: roles-ops-development
# Bundles DevOps tools (k9s, kubectl, helm, awscli).
# Enables k9s program aspect.
{ ... }:
let
  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.opsDevelopment = {
        enable = lib.mkEnableOption "devops developer tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.opsDevelopment;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs.k9s.enable = true;

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
  flake.modules.nixos.roles-ops-development = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-ops-development = mkConfig { isDarwin = true; };
}
