# Host configuration: nixos-desktop
# Single source of truth — selector + identity + machine-specific config.
{ inputs, self, ... }:
let
  system = "x86_64-linux";

  # python311 sphinx-9.1.0 fix: sphinx dropped python3.11, but ceph and the
  # jaraco ecosystem (cherrypy → jaraco-collections → inflect) still need it.
  #
  # Two layers needed:
  #   1. Override python311 globally (fixes non-ceph packages like cherrypy)
  #   2. Override ceph to compose sphinx fix WITH ceph's internal overrides
  #      (ceph calls python311.override{packageOverrides=X} which replaces layer 1)
  sphinxFix = pself: psuper: {
    sphinx = psuper.sphinx.overridePythonAttrs { disabled = false; };
  };

  python311SphinxOverlay = final: prev: let
    py = prev.python311.override {
      self = py;
      packageOverrides = sphinxFix;
    };
  in {
    python311 = py;
    # Ceph internally does python311.override { packageOverrides = cephPkgOverrides }
    # which REPLACES our packageOverrides. Fix: override ceph-client to use a python311
    # where sphinxFix is pre-composed into any future packageOverrides.
    ceph = prev.ceph.override {
      python311 = let
        base = prev.python311;
        origOverride = base.override;
      in base // {
        override = attrs:
          origOverride (attrs // {
            packageOverrides =
              if attrs ? packageOverrides then
                prev.lib.composeExtensions sphinxFix attrs.packageOverrides
              else
                sphinxFix;
          });
      };
    };
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
          _:
          {
            # Fix: sphinx 9.1.0 dropped python3.11; ceph + jaraco ecosystem need it.
            nixpkgs.overlays = [ python311SphinxOverlay ];
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


          }
        )
        # Secrets configuration - make secrets readable by the user
        (
          { config, ... }:
          let
            inherit (config.jvf.core) username;
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
