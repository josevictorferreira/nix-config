# Dendritic host selector: nixos-desktop
# Defines flake.nixosConfigurations.nixos-desktop using aspects list.
# Host-specific settings remain in hosts/nixos-desktop/config.nix.
{ inputs, self, ... }:
let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs.bun2nix.overlays.default ];
    config.allowUnfree = true;
  };

  # Compatibility: specialArgs still passed until all modules migrate to jvf.core.*
  specialArgs = {
    os = "nixos";
    username = "josevictor";
    host = "nixos-desktop";
    inherit system;
    inputs = inputs // {
      inherit (inputs) self;
      lib = import ../../lib {
        lib = pkgs.lib;
        inherit pkgs system;
      };
    };
  };
in
{
  flake.nixosConfigurations.nixos-desktop = inputs.nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    modules = [
      # External modules
      inputs.sops-nix.nixosModules.sops
      inputs.distro-grub-themes.nixosModules.${system}.default

      # Core options
      ../../modules/core/options.nix

      # Dendritic aspect: jvf core (users, hardware, system, roles)
      self.modules.nixos.core-jvf

      # Dendritic aspect: Hyprland desktop (nixos only)
      self.modules.nixos.desktop-hyprland

      # Host-specific config (last, so it can override)
      ../../hosts/nixos-desktop/config.nix
    ];
  };
}
