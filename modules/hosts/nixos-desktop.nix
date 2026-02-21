# Dendritic host selector: nixos-desktop
# Defines flake.nixosConfigurations.nixos-desktop using aspects list.
# Host-specific settings remain in hosts/nixos-desktop/config.nix.
{ inputs, ... }:
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

      # Legacy aspects (until migrated to dendritic)
      ../../modules/legacy/_/users/repositories.nix
      ../../modules/legacy/_/users/wrappers.nix
      ../../modules/legacy/_/users/default.nix
      ../../modules/legacy/_/hardware/default.nix
      ../../modules/legacy/_/system/default.nix
      ../../modules/legacy/_/roles/default.nix

      # Host-specific config (last, so it can override)
      ../../hosts/nixos-desktop/config.nix
    ];
  };
}
