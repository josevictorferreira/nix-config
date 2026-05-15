# Aspect: system-flatpak
# Defines jvf.system.flatpak options and platform-specific Flatpak config.
# NixOS: flatpak service, rpcbind, Flathub repo setup.
# Darwin: empty config (Flatpak not available on macOS).
_:
let
  mkFlatpakOptions =
    { lib, ... }:
    {
      options.jvf.system.flatpak = {
        enableFlathub = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically add Flathub repository during system activation.";
        };
      };
    };

  nixosModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.system.flatpak;
    in
    {
      imports = [ mkFlatpakOptions ];

      config = {
        services.flatpak.enable = true;

        services.rpcbind.enable = true;

        systemd.services.flatpak-repo = lib.mkIf cfg.enableFlathub {
          path = [ pkgs.flatpak ];
          script = ''
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
          '';
        };
      };
    };
in
{
  flake.modules.nixos.system-flatpak = nixosModule;
}
