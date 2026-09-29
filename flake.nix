{
  description = "JoseVictor Nix Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "nixpkgs/nixpkgs-unstable";
    # Pinned to the newest nixos-unstable revision whose ceph Hydra has built and
    # cached; zeh-pc takes ceph from here. Bump only after confirming the new
    # ceph-client is on cache.nixos.org (see modules/hosts/zeh-pc/default.nix).
    nixpkgs-ceph.url = "github:NixOS/nixpkgs/60f402c45f5cf7c200060bfbd959b626ce088cf2";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";
    distro-grub-themes.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    bun2nix.url = "github:nix-community/bun2nix";
    pi-plugins.url = "github:josevictorferreira/my-pi-agent-plugins";
    pi-plugins.flake = false;
    nvim-config.url = "github:josevictorferreira/.nvim";
    nvim-config.flake = false;
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      # Auto-discover all flake-parts modules via import-tree (recursive, skips paths with /_)
      # Non-flake-parts files (e.g. core/_/options.nix) use /_ path to avoid auto-import.
      imports = [
        (inputs.import-tree ./modules)
      ];

      # perSystem (pkgs, formatter, overlays) defined in modules/overlays.nix
      # flake.templates defined in modules/flake/templates.nix
    };
}
