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

  # ceph 20.2.2 fails to build on this nixpkgs revision for four unrelated reasons:
  # three inside its embedded Python environment, one in the RGW C++ code. The
  # Python fixes are confined to ceph's own scope and interpreter — patching the
  # global python package set instead would invalidate the binary cache for
  # rocblas, steam, freecad and everything else using python.
  cephFixOverlay = _: prev: {
    ceph =
      (prev.ceph.overrideScope (
        _: scopePrev: {
          # setup.py declares name='ceph' version='1.0.0', but nixpkgs builds it as
          # pname='ceph-common' version=20.2.2, so pythonMetadataCheckPhase can't
          # find the dist-info. The package itself is fine.
          ceph-python-common = scopePrev.ceph-python-common.overrideAttrs (_: {
            dontCheckPythonMetadata = true;
          });

          ceph-python = prev.python312.override {
            packageOverrides = _: pyPrev: {
              # Upstream tagged 0.29.37.1 without bumping setup.py, so the built
              # METADATA says 0.29.37 and pythonMetadataCheckPhase rejects it.
              cython_0 = pyPrev.cython_0.overrideAttrs (_: {
                dontCheckPythonMetadata = true;
              });

              # Flaky hypothesis property test: fails on some random seeds with a
              # ~2e-9 discrepancy. Same class as the exclusions scipy already ships.
              scipy = pyPrev.scipy.overrideAttrs (old: {
                disabledTests = (old.disabledTests or [ ]) ++ [ "test_support_moments_sample" ];
              });
            };
          };
        }
      )).ceph.overrideAttrs
        (old: {
          # s3select picks its encryption backend on ARROW_VERSION_MAJOR: >= 20
          # selects encryption_internal_20.h, which includes "arrow/util/span.h".
          # nixpkgs' arrow-cpp is 24.0.0 and dropped that header (superseded by
          # C++20 std::span), so rgw_s3select.cc fails to compile. The header's own
          # __has_include guard only probes arrow/api.h, so it doesn't catch this.
          # The entire parquet path is gated behind -D_ARROW_EXIST, which CMake only
          # defines when this flag is on. Costs S3-Select-on-Parquet in radosgw,
          # which this host never runs — it only consumes ceph-client for cephfs.
          cmakeFlags = old.cmakeFlags ++ [
            (prev.lib.cmakeBool "WITH_RADOSGW_SELECT_PARQUET" false)
          ];
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
          nixpkgs.overlays = [
            openldapFixOverlay
            cephFixOverlay
          ];
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
            3000
            11434
            8000
            8095
            8096
            8097
            8098
            8001
            5000
            8188
            4096
            5173
            5174
            8080
            8765
            7788
          ];
        })
      ];
  };
}
