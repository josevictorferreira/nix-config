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
    sphinx = psuper.sphinx.overridePythonAttrs (old: {
      version = "8.1.3";
      src = psuper.fetchPypi {
        pname = "sphinx";
        version = "8.1.3";
        sha256 = "sha256-Q8GRHuyw0+FhrXhhG8kF0a0OUj5N3CAqWKghdz3EySc=";
      };
      disabled = false;
      doCheck = false;
      dontCheckRuntimeDeps = true;
      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ psuper.roman ];
    });
    watchdog = psuper.watchdog.overridePythonAttrs { doCheck = false; };
    sh = psuper.sh.overridePythonAttrs { doCheck = false; };
    sphinx-pytest = psuper.sphinx-pytest.overridePythonAttrs { doCheck = false; };
    typeguard = psuper.typeguard.overridePythonAttrs (old: {
      doCheck = false;
      outputs = [ "out" ];
      nativeBuildInputs = builtins.filter (
        p: (p.pname or "") != "sphinxHook" && (p.pname or "") != "sphinx"
      ) (old.nativeBuildInputs or [ ]);
      postBuild = "";
    });
    sphinx-autodoc-typehints = psuper.buildPythonPackage {
      pname = "sphinx-autodoc-typehints";
      version = "9.9.9";
      src = psuper.pkgs.runCommand "empty" { } "mkdir -p $out";
      format = "other";
      dontBuild = true;
      doCheck = false;
      installPhase = ''
        mkdir -p $out/lib/python3.11/site-packages/sphinx_autodoc_typehints
        touch $out/lib/python3.11/site-packages/sphinx_autodoc_typehints/__init__.py
      '';
    };
    sphinx-basic-ng = psuper.sphinx-basic-ng.overridePythonAttrs {
      doCheck = false;
      dontBuildDocs = true;
      pythonImportsCheck = [ ];
    };
    myst-parser = psuper.myst-parser.overridePythonAttrs {
      doCheck = false;
      dontBuildDocs = true;
      pythonImportsCheck = [ ];
    };
    tornado = psuper.tornado.overridePythonAttrs { doCheck = false; };
    cherrypy = psuper.cherrypy.overridePythonAttrs { doCheck = false; };
    paramiko = psuper.paramiko.overridePythonAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
      dontCheckRuntimeDeps = true;
    });
    ipython = psuper.ipython.overridePythonAttrs { doCheck = false; };
    cryptography = psuper.cryptography.overridePythonAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
      pytestCheckPhase = "true";
      checkPhase = "true";
    });
  };

  python311SphinxOverlay =
    final: prev:
    let
      py = prev.python311.override {
        self = py;
        packageOverrides = sphinxFix;
      };
    in
    {
      python311 = py;
      # Ceph internally does python311.override { packageOverrides = cephPkgOverrides }
      # which REPLACES our packageOverrides. Fix: override ceph-client to use a python311
      # where sphinxFix is pre-composed into any future packageOverrides.
      ceph = prev.ceph.override {
        ceph-arrow-cpp = (prev.ceph.arrow-cpp.override { boost = prev.boost186; }).overrideAttrs (old: {
          doCheck = false;
        });
        python311 =
          let
            base = prev.python311;
            origOverride = base.override;
          in
          base
          // {
            override =
              attrs:
              origOverride (
                attrs
                // {
                  packageOverrides =
                    if attrs ? packageOverrides then
                      prev.lib.composeExtensions attrs.packageOverrides sphinxFix
                    else
                      sphinxFix;
                }
              );
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
        core-theme
        users
        wrappers
        repositories
        secrets-sops
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
        desktop-hyprland-thunar
        desktop-hyprland-xfce4
        desktop-hyprland-gtk3
        desktop-hyprland-fastfetch
        desktop-hyprland-swappy
        desktop-hyprland-wlogout
        boot-grub-theme

        # System infra (not pulled by roles)
        system-locale
        system-nixpkgs
        system-nix-daemon
        system-security
        system-tailscale
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
          # Fix: sphinx 9.1.0 dropped python3.11; ceph + jaraco ecosystem need it.
          # Fix: arrow-cpp 19.0.1 fails to build with boost 1.89.0; force boost188.
          nixpkgs.overlays = [ python311SphinxOverlay ];
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
