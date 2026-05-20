# Host configuration: nixos-desktop
# Single source of truth — selector + identity + machine-specific config.
{ inputs, self, ... }:
let
  system = "x86_64-linux";

  # openldap-2.6.13 fails with syncreplication tests after nixpkgs update.
  # This is a common transient build failure; disable tests as a workaround.
  openldapFixOverlay = final: prev: {
    openldap = prev.openldap.overrideAttrs (old: {
      doCheck = false;
    });
  };

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.bun2nix.overlays.default
    ];
  };

  # Minimal specialArgs: only inputs (needed by sops, ai-tools, etc.)
  specialArgs = {
    inputs = inputs // {
      inherit (inputs) self;
      lib = import ../../../lib {
        inherit (pkgs) lib;
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
        # Core infrastructure
        core-jvf
        core-theme
        users
        wrappers
        repositories
        secrets-sops
        secrets-environment
        home

        # Desktop environment
        desktop-hyprland
        desktop-hyprland-hypr
        desktop-hyprland-ags
        desktop-hyprland-rofi
        desktop-hyprland-swaync
        desktop-hyprland-waybar
        desktop-hyprland-cava
        desktop-hyprland-qt5ct
        desktop-hyprland-qt6ct
        desktop-hyprland-kvantum
        desktop-hyprland-xfce4
        desktop-hyprland-gtk3
        desktop-hyprland-fastfetch
        desktop-hyprland-swappy
        desktop-hyprland-wlogout
        desktop-hyprland-wallust
        boot-grub-theme

        # System infra (not pulled by roles)
        system-locale
        system-nixpkgs
        system-nix-daemon
        system-security
        # system-tailscale
        system-lights-off

        # Hardware
        hardware-boot
        hardware-btrfs
        hardware-amd-gpu
        hardware-bluetooth
        hardware-logitech
        hardware-openrgb

        # Roles (pull programs/services/system deps transitively)
        roles-base
        roles-desktop
        roles-development
        roles-ai-development
        roles-local-ai
        roles-ops-development
        roles-monitoring
        roles-communication
        roles-designing
        roles-media
        roles-gaming
        roles-network-storage
        roles-documenting
        roles-privacy

        # AI tools DSL
        ai-tools-skills
        ai-tools-agents
        ai-tools-commands
        ai-tools-mcp
        ai-tools-rules
        ai-tools-scripts
      ])
      ++ [
        # Machine-specific hardware (filesystems, UUIDs, swap)
        ./_/hardware.nix

        # Host identity & overrides
        (_: {
          # Fix: arrow-cpp 19.0.1 fails to build with boost 1.89.0; force boost188.
          nixpkgs.overlays = [ openldapFixOverlay ];
          system.stateVersion = "26.05";
          # Core identity
          jvf.core = {
            username = "josevictor";
            host = "nixos-desktop";
            os = "nixos";
          };
          jvf.programs.tmuxp.enable = true;

          # User configuration
          jvf.users.josevictor = {
            description = "Jose Victor Ferreira";
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@macos-macbook"
            ];
          };

          # XDG user directories (host-specific)
          jvf.system.xdg.userDirs = {
            DESKTOP = "$HOME/Desktop";
            DOWNLOAD = "$HOME/Downloads";
            DOCUMENTS = "$HOME/Documents";
            MUSIC = "$HOME/Music";
            PICTURES = "$HOME/Pictures";
            VIDEOS = "$HOME/Videos";
            TEMPLATES = "$HOME/Templates";
            PUBLICSHARE = "$HOME/Public";
          };

          # Static IP configuration (host-specific)
          networking.interfaces.enp4s0.ipv4.addresses = [
            {
              address = "10.10.10.10";
              prefixLength = 24;
            }
          ];
          networking.interfaces.enp4s0.useDHCP = false;
          networking.defaultGateway = "10.10.10.1";
          networking.nameservers = [ "10.10.10.100" ];

          # Open port for OpenCode Web
          jvf.system.firewall.allowedTCPPorts = [
            8000
            8188
            4096
            5173
          ];
        })
      ];
  };
}
