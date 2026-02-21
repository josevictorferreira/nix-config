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
    modules =
      # Dendritic aspects
      (with self.modules.nixos; [
        core-jvf
        secrets-sops
        desktop-hyprland
      ])
      # External modules (not yet wrapped as aspects)
      ++ [
        inputs.distro-grub-themes.nixosModules.${system}.default
        ../../modules/core/options.nix
      ]
      # Host-specific config (last, so it can override)
      ++ [
        ../../hosts/nixos-desktop/config.nix
      ];
  };
}
