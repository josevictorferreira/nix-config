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
      # Dendritic aspects (all NixOS modules via import-tree)
      (with self.modules.nixos; [
        core-jvf
        users
        secrets-sops
        desktop-hyprland
        boot-grub-theme
      ])
      # Host-specific config (last, so it can override)
      ++ [
        ../../hosts/nixos-desktop/config.nix
      ];
  };
}
