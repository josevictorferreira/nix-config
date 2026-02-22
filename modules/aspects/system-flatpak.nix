# Aspect: system-flatpak
# Defines jvf.system.flatpak options and platform-specific Flatpak config.
# NixOS: flatpak service, rpcbind, Flathub repo setup.
# Darwin: empty config (Flatpak not available on macOS).
{ ... }:
let
  mkFlatpakOptions =
    { lib, ... }:
    {
      options.jvf.system.flatpak = {
        enable = lib.mkEnableOption "flatpak support" // {
          description = ''
            Whether to enable Flatpak support and setup common repositories.
            Includes Flathub repository configuration.
          '';
        };

        enableFlathub = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically add Flathub repository during system activation.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.system.flatpak;
    in
    {
      imports = [ mkFlatpakOptions ];

      config = lib.mkIf cfg.enable (
        if (!isDarwin) then
          {
            services.flatpak.enable = true;

            services.rpcbind.enable = true;

            systemd.services.flatpak-repo = lib.mkIf cfg.enableFlathub {
              path = [ pkgs.flatpak ];
              script = ''
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
              '';
            };
          }
        else
          { }
      );
    };
in
{
  flake.modules.nixos.system-flatpak = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-flatpak = mkConfig { isDarwin = true; };
}
