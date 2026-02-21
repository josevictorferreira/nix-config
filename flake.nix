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

      # Auto-discover flake-parts modules via import-tree (ignores paths containing /_)
      # Legacy NixOS/Darwin modules live under modules/legacy/_/ and are imported
      # only through aspects (e.g. core-jvf, desktop-hyprland).
      imports = [
        (inputs.import-tree ./modules/flake)
        (inputs.import-tree ./modules/hosts)
        (inputs.import-tree ./modules/aspects)
      ];

      # perSystem (pkgs, formatter, overlays) defined in modules/aspects/overlays.nix

      flake = {
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
