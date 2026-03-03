# Aspect: system-virtualization
# Defines jvf.system.virtualization options and platform-specific virtualization config.
# NixOS: libvirtd, podman with Docker compat, container settings.
# Darwin: empty config (virtualization handled natively by macOS).
_:
let
  mkVirtualizationOptions =
    { config, lib, ... }:
    {
      options.jvf.system.virtualization = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "The username to use for virtualization services.";
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
      cfg = config.jvf.system.virtualization;
    in
    {
      imports = [ mkVirtualizationOptions ];

      config =
        if (!isDarwin) then
          {
            virtualisation.libvirtd.enable = lib.mkDefault false;
            virtualisation.podman = {
              enable = true;
              dockerCompat = true;
              defaultNetwork.settings.dns_enabled = true;
              autoPrune.dates = "monthly";
            };

            users.users."${cfg.username}".packages = [
              pkgs.podman
              pkgs.podman-tui
              pkgs.podman-compose
              pkgs.dive
            ];

            virtualisation.containers = {
              enable = true;

              policy = {
                default = [
                  {
                    type = "insecureAcceptAnything";
                  }
                ];
              };

              containersConf.settings = {
                engine = {
                  num_workers = 8;
                };

                image.copy = {
                  max_concurrent_downloads = 8;
                };
              };
            };
          }
        else
          { };
    };
in
{
  flake.modules.nixos.system-virtualization = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-virtualization = mkConfig { isDarwin = true; };
}
