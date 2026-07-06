# Host configuration: macos-macbook
# Single source of truth — selector + identity + machine-specific config.
{ inputs, self, ... }:
let
  system = "aarch64-darwin";

  # Fix libfyaml pkg-config leaking " none required" into linker args (nixpkgs#514566)
  libfyamlOverlay = final: prev: {
    libfyaml = prev.libfyaml.overrideAttrs (previousAttrs: {
      postInstall = (previousAttrs.postInstall or "") + ''
        substituteInPlace "$dev/lib/pkgconfig/libfyaml.pc" \
          --replace-fail " none required" ""
      '';
    });
  };

  pkgs = import inputs.nixpkgs-darwin {
    inherit system;
    overlays = [
      inputs.bun2nix.overlays.default
      libfyamlOverlay
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
  flake.darwinConfigurations.macos-macbook = inputs.darwin.lib.darwinSystem {
    inherit specialArgs;
    modules =
      # Dendritic aspects (all Darwin modules via import-tree)
      (with self.modules.darwin; [
        # Core infrastructure
        core-jvf
        core-theme
        users
        wrappers
        repositories
        secrets-sops
        secrets-environment
        home
        darwin-defaults

        # System infra (not pulled by roles)
        system-locale
        system-nixpkgs
        system-nix-daemon
        system-security
        system-terminal-artifacts
        system-terminal-apps

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
        # Platform binding
        {
          nixpkgs.hostPlatform = system;
          nixpkgs.overlays = [
            inputs.bun2nix.overlays.default
            libfyamlOverlay
          ];
        }

        # Host identity & overrides
        (_: {
          # Core identity
          jvf.core = {
            username = "josevictorferreira";
            host = "macos-macbook";
            os = "macos";
          };

          # Enable tmuxp session manager (kitty launches tmuxp-init → main session)
          jvf.programs.tmuxp.enable = true;

          # macOS primary user (required by nix-darwin)
          system.primaryUser = "josevictorferreira";

          # User configuration
          jvf.users.josevictorferreira = {
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAXdWHFx9UwUOXlapiVD0mzM0KL9VsMlblMAc46D9PV josevictor@josevictor-nixos"
            ];
          };

          system.stateVersion = 4;
        })
      ];
  };
}
