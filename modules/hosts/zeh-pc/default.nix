# Host configuration: zeh-pc
# Single source of truth — selector + identity + machine-specific config.
{ inputs, self, ... }:
let
  system = "x86_64-linux";

  # cephfs only needs ceph-client (mount.ceph). Hydra builds ceph rarely and the
  # nixos-unstable channel doesn't wait for it, so at most revisions ceph is a
  # cache miss and a multi-hour local build. Take it from a pinned nixpkgs whose
  # ceph Hydra has already built, so it's a download regardless of main bumps.
  # ceph-client is ceph's `client` output, so pinning ceph covers it.
  cephPinOverlay = _: _: {
    inherit (inputs.nixpkgs-ceph.legacyPackages.${system}) ceph;
  };

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.bun2nix.overlays.default
    ];
  };

  # Minimal specialArgs: only inputs (needed by sops, zeh-ai-tooling, etc.)
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
  flake.nixosConfigurations.zeh-pc = inputs.nixpkgs.lib.nixosSystem {
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
        desktop-hyprland-theme-switcher
        boot-grub-theme

        # System infra (not pulled by roles)
        system-locale
        system-nixpkgs
        system-nix-daemon
        system-security
        # system-tailscale
        system-lights-off
        system-terminal-artifacts

        # Hardware
        hardware-boot
        hardware-btrfs
        hardware-amd-gpu
        hardware-bluetooth
        hardware-airpods
        hardware-logitech
        hardware-openrgb
        hardware-moonlander

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

      ])
      ++ [
        # Machine-specific hardware (filesystems, UUIDs, swap)
        ./_/hardware.nix

        # Host identity & overrides
        (_: {
          nixpkgs.overlays = [
            cephPinOverlay
          ];
          system.stateVersion = "26.05";
          # Core identity
          jvf.core = {
            username = "josevictor";
            host = "zeh-pc";
            os = "nixos";
          };
          jvf.programs.tmuxp.enable = true;

          # User configuration
          jvf.users.josevictor = {
            description = "Jose Victor Ferreira";
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@zeh-mac"
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
          networking.nameservers = [
            "10.10.10.100"
            "1.1.1.1"
            "8.8.8.8"
          ];

          # Open port for OpenCode Web
          jvf.system.firewall.allowedTCPPorts = [
            3000
            11434
            8000
            8001
            8095
            8096
            8097
            8098
            8099
            8001
            5000
            8188
            4096
            5173
            5174
            8080
            8102
            8765
            8766
            7788
          ];
        })
      ];
  };
}
