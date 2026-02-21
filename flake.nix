{
  description = "JoseVictor Nix Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";
    distro-grub-themes.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    bun2nix.url = "github:nix-community/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      # Import modules via import-tree (ignores paths containing /_)
      # Legacy NixOS/Darwin modules in modules/{users,hardware,system,roles,...}
      # are NOT auto-imported since import-tree ignores paths containing /_
      # They are imported explicitly in nixosModule/darwinModule below.
      imports = [
        (inputs.import-tree ./modules/flake)
        (inputs.import-tree ./modules/hosts)
      ];

      perSystem =
        { system, ... }:
        let
          pkgs =
            import (if builtins.match ".*-darwin" system != null then inputs.nixpkgs-darwin else inputs.nixpkgs)
              {
                inherit system;
                overlays = [ inputs.bun2nix.overlays.default ];
                config = {
                  allowUnfree = true;
                };
              };
        in
        {
          # Formatter
          formatter = pkgs.nixpkgs-fmt;
        };

      flake =
        let
          forAllSystems = inputs.nixpkgs.lib.genAttrs [
            "x86_64-linux"
            "aarch64-darwin"
          ];

          systems = {
            # nixos host config moved to modules/hosts/nixos-desktop.nix
            macos = {
              systemArc = "aarch64-darwin";
              os = "macos";
              host = "macos-macbook";
              username = "josevictorferreira";
            };
          };

          mkPkgs =
            systemArc:
            import
              (if builtins.match ".*-darwin" systemArc != null then inputs.nixpkgs-darwin else inputs.nixpkgs)
              {
                system = systemArc;
                overlays = [ inputs.bun2nix.overlays.default ];
                config = {
                  allowUnfree = true;
                };
              };

          specialArgsFor =
            {
              systemArc,
              os,
              host,
              username,
            }:
            let
              pkgs = mkPkgs systemArc;
            in
            {
              inherit
                os
                username
                host
                ;
              system = systemArc;
              inputs = inputs // {
                inherit self;
                lib = import ./lib {
                  lib = pkgs.lib;
                  inherit pkgs;
                  system = systemArc;
                };
              };
            };

          # nixosModule moved to modules/hosts/nixos-desktop.nix (dendritic)

          darwinModule =
            { systemArc, host, ... }:
            inputs.darwin.lib.darwinSystem {
              specialArgs = specialArgsFor systems.macos;
              system = systemArc;
              modules = [
                inputs.sops-nix.darwinModules.sops
                ./hosts/${host}/config.nix
                ./modules/core/options.nix
                ./modules/legacy/_/users/repositories.nix
                ./modules/legacy/_/users/wrappers.nix
                ./modules/legacy/_/users/default.nix
                ./modules/legacy/_/hardware/default.nix
                ./modules/legacy/_/system/default.nix
                ./modules/legacy/_/roles/default.nix
              ];
            };

        in
        {
          # Per-system lib output with mkSandboxShell (Phase 2 integration)
          lib = forAllSystems (
            system:
            let
              pkgs = mkPkgs system;
              baseLib = import ./lib {
                lib = pkgs.lib;
                inherit pkgs system;
              };
            in
            baseLib
            // {
              inherit pkgs;
            }
          );

          # nixosConfigurations.nixos-desktop now defined in modules/hosts/nixos-desktop.nix

          darwinConfigurations = {
            ${systems.macos.host} = darwinModule systems.macos;
          };

          templates = {
            sandbox-postgres-ruby = {
              path = ./templates/sandbox-postgres-ruby;
              description = "Sandbox with PostgreSQL 16 and Ruby 3.3";
            };
            sandbox-postgres-django = {
              path = ./templates/sandbox-postgres-django;
              description = "Sandbox with PostgreSQL (PostGIS/TimescaleDB) and Django";
            };
            frontend-bun-vite = {
              path = ./templates/frontend-bun-vite;
              description = "Frontend template using Bun and Vite.js";
            };
          };
        };
    };
}
