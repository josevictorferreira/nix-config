{
  description = "JoseVictor Nix Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "nixpkgs/nixpkgs-unstable";
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
    inputs@{ self
    , nixpkgs
    , darwin
    , sops-nix
    , ...
    }:
    let
      systems = {
        nixos = {
          systemArc = "x86_64-linux";
          os = "nixos";
          host = "nixos-desktop";
          username = "josevictor";
        };
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
        { systemArc
        , os
        , host
        , username
        ,
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

      nixosModule =
        { systemArc, host, ... }:
        nixpkgs.lib.nixosSystem {
          specialArgs = specialArgsFor (systems.nixos);
          modules = [
            sops-nix.nixosModules.sops
            ./hosts/${host}/config.nix
            ./modules/users/repositories.nix
            ./modules/users/wrappers.nix
            inputs.distro-grub-themes.nixosModules.${systemArc}.default
            ./modules/users/default.nix
            ./modules/hardware/default.nix
            ./modules/system/default.nix
            ./modules/roles/default.nix
          ];
        };

      darwinModule =
        { systemArc, host, ... }:
        darwin.lib.darwinSystem {
          specialArgs = specialArgsFor (systems.macos);
          system = systemArc;
          modules = [
            sops-nix.darwinModules.sops
            ./hosts/${host}/config.nix
            ./modules/users/repositories.nix
            ./modules/users/wrappers.nix
            ./modules/users/default.nix
            ./modules/hardware/default.nix
            ./modules/system/default.nix
            ./modules/roles/default.nix
          ];
        };

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

    in
    {
      # Per-system lib output with mkSandboxShell (Phase 2 integration)
      lib = forAllSystems (system:
        let
          pkgs = mkPkgs system;
          baseLib = import ./lib {
            lib = pkgs.lib;
            inherit pkgs system;
          };
        in
        baseLib // {
          inherit pkgs;
        }
      );

      nixosConfigurations = {
        ${systems.nixos.host} = nixosModule systems.nixos;
      };

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
        monorepo-subtrees = {
          path = ./templates/monorepo-subtrees;
          description = "Monorepo helpers for git subtrees (backend/frontend)";
        };
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
