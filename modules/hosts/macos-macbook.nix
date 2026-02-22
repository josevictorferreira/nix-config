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
    modules =
      # Dendritic aspects (all Darwin modules via import-tree)
      (with self.modules.darwin; [
        core-jvf
        users
        wrappers
        repositories
        secrets-sops
        darwin-defaults
        system-base-programs
        system-base-services
        system-locale
        system-networking
        system-nixpkgs
        system-nix-daemon
        system-security
        system-xdg
        system-environment
        system-display
        system-firewall
        system-flatpak
        system-logind
        system-power-management
        system-virtualization
        system-audio
        # Program aspects (Phase 3)
        programs-alacritty
        programs-btop
        programs-ck-search
        programs-easyeffects
        programs-ghostty
        programs-git
        programs-k9s
        programs-kitty
        programs-mistral-vibe
        programs-neovim
        programs-starship
        programs-steam
        programs-tmux
        programs-zsh
        # Service aspects (Phase 5 - smb and llm-proxy only, cephfs is NixOS-only)
        services-smb
        services-llm-proxy
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
