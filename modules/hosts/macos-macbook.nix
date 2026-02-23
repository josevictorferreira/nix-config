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

  # Minimal specialArgs: only inputs (needed by sops, ai-tools, etc.)
  specialArgs = {
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
    modules =
      # Dendritic aspects (all Darwin modules via import-tree)
      (with self.modules.darwin; [
        # Core infrastructure
        core-jvf
        users
        wrappers
        repositories
        secrets-sops
        darwin-defaults

        # System infra (not pulled by roles)
        system-locale
        system-nixpkgs
        system-nix-daemon
        system-security

        # Roles (pull programs/services/system deps transitively)
        roles-base
        roles-development
        roles-ai-development
        roles-ops-development
        roles-monitoring
        roles-communication
        roles-network-storage

        # AI tools DSL
        ai-tools-skills
        ai-tools-agents
        ai-tools-commands
        ai-tools-mcp
        ai-tools-rules
        ai-tools-scripts
      ])
      ++ [
        # Platform identity (required for pkgs resolution in legacy modules)
        { nixpkgs.hostPlatform = system; }
      ]
      # Host-specific config (last, so it can override)
      ++ [
        ../../hosts/macos-macbook/config.nix
      ];
  };
}
