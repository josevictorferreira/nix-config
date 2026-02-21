# Dendritic host selector: macos-macbook
# Defines flake.darwinConfigurations.macos-macbook using aspects list.
# Host-specific settings remain in hosts/macos-macbook/config.nix.
{ inputs, self, ... }:
let
  system = "aarch64-darwin";

  pkgs = import inputs.nixpkgs-darwin {
    inherit system;
    overlays = [ inputs.bun2nix.overlays.default ];
    config.allowUnfree = true;
  };

  # Compatibility: specialArgs still passed until all modules migrate to jvf.core.*
  specialArgs = {
    os = "macos";
    username = "josevictorferreira";
    host = "macos-macbook";
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
  flake.darwinConfigurations.macos-macbook = inputs.darwin.lib.darwinSystem {
    inherit specialArgs;
    modules = [
      # Platform identity (required for pkgs resolution in legacy modules)
      { nixpkgs.hostPlatform = system; }

      # External modules
      inputs.sops-nix.darwinModules.sops

      # Core options
      ../../modules/core/options.nix

      # Dendritic aspect: jvf core (users, system, roles)
      self.modules.darwin.core-jvf

      # Dendritic aspect: macOS defaults (darwin only)
      self.modules.darwin.darwin-defaults

      # Host-specific config (last, so it can override)
      ../../hosts/macos-macbook/config.nix
    ];
  };
}
