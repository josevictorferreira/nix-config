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
        wrappers
        repositories
        secrets-sops
        desktop-hyprland
        # Hyprland sub-aspects (Phase 8)
        desktop-hyprland-hypr
        desktop-hyprland-ags
        desktop-hyprland-rofi
        desktop-hyprland-swaync
        desktop-hyprland-waybar
        desktop-hyprland-cava
        desktop-hyprland-qt5ct
        desktop-hyprland-qt6ct
        desktop-hyprland-kvantum
        desktop-hyprland-thunar
        desktop-hyprland-xfce4
        desktop-hyprland-gtk3
        desktop-hyprland-fastfetch
        desktop-hyprland-swappy
        desktop-hyprland-wallust
        desktop-hyprland-wlogout
        boot-grub-theme
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
        # Hardware aspects (Phase 6)
        hardware-amd-gpu
        hardware-bluetooth
        hardware-logitech
        hardware-openrgb
        # Program aspects (Phase 3)
        programs-alacritty
        programs-btop
        programs-ck-search
        programs-claudecode
        programs-cursor
        programs-droid
        programs-easyeffects
        programs-gemini
        programs-ghostty
        programs-git
        programs-k9s
        programs-kitty
        programs-mistral-vibe
        programs-neovim
        programs-opencode
        programs-starship
        programs-steam
        programs-tmux
        programs-weechat
        programs-zsh
        # Service aspects (Phase 5)
        services-smb
        services-cephfs
        services-llm-proxy
        # Role aspects (Phase 7)
        roles-development
        roles-monitoring
        roles-media
        roles-privacy
        roles-gaming
        roles-ai-development
        roles-local-ai
        roles-communication
        roles-designing
        roles-documenting
        roles-network-storage
        roles-ops-development
        # AI Tools aspects (Phase 9)
        ai-tools
        ai-tools-skills
        ai-tools-agents
        ai-tools-commands
        ai-tools-mcp
        ai-tools-rules
        ai-tools-scripts
      ])
      # Host-specific config (last, so it can override)
      ++ [
        ../../hosts/nixos-desktop/config.nix
      ];
  };
}
