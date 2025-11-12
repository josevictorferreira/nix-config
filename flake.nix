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
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      sops-nix,
      ...
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
            overlays = [ ];
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
          ];
        };

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

    in
    {
      lib =
        systemArc:
        let
          pkgs = mkPkgs systemArc;
        in
        import ./lib {
          lib = pkgs.lib;
          inherit pkgs;
        };

      nixosConfigurations = {
        ${systems.nixos.host} = nixosModule systems.nixos;
      };

      darwinConfigurations = {
        ${systems.macos.host} = darwinModule systems.macos;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
