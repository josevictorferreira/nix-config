# Host configuration: nixos-desktop
# Single source of truth — selector + identity + machine-specific config.
{ inputs, self, ... }:
let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs.bun2nix.overlays.default ];
    config.allowUnfree = true;
  };

  # Minimal specialArgs: only inputs (needed by sops, ai-tools, etc.)
  specialArgs = {
    inputs = inputs // {
      inherit (inputs) self;
      lib = import ../../../lib {
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
        # Core infrastructure
        core-jvf
        users
        wrappers
        repositories
        secrets-sops

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
        desktop-hyprland-thunar
        desktop-hyprland-xfce4
        desktop-hyprland-gtk3
        desktop-hyprland-fastfetch
        desktop-hyprland-swappy
        desktop-hyprland-wallust
        desktop-hyprland-wlogout
        boot-grub-theme

        # System infra (not pulled by roles)
        system-locale
        system-nixpkgs
        system-nix-daemon
        system-security

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
        (
          { ... }:
          {
            # Core identity
            jvf.core = {
              username = "josevictor";
              host = "nixos-desktop";
              os = "nixos";
            };

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

            system.stateVersion = "24.05";
          }
        )
        # Secrets configuration - make secrets readable by the user
        (
          { config, ... }:
          let
            username = config.jvf.core.username;
            secretKeys = config.jvf.programs.zsh.secrets.keys;
          in
          {
            # Declare all zsh secrets with user ownership so they can be read
            sops.secrets = builtins.listToAttrs (
              map (key: {
                name = key;
                value = {
                  owner = username;
                  group = "users";
                  mode = "0400";
                };
              }) secretKeys
            );
          }
        )
      ];
  };
}
