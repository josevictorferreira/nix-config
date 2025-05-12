{
  description = "JoseVictor Nix Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "nixpkgs/nixpkgs-unstable";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";
    sops-nix.url = "github:Mic92/sops-nix";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, darwin, sops-nix, home-manager, ... }:
    let
      systems = {
        nixos = {
          systemArc = "x86_64-linux";
          os = "nixos";
          host = "nixos-desktop";
          username = "josevictor";
          isDarwin = false;
          isNixOS = true;
        };
        macos = {
          systemArc = "aarch64-darwin";
          os = "macos";
          host = "macos-macbook";
          username = "josevictorferreira";
          isDarwin = true;
          isNixOS = false;
        };
      };

      specialArgsFor = { systemArc, os, host, username, isDarwin, isNixOS }: {
        inherit inputs os systemArc username host;
        configRoot = ./.;
        inherit isDarwin isNixOS;
      };

      homeManagerConfig = { systemArc, os, host, username, isDarwin, isNixOS, ... }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = specialArgsFor { inherit systemArc os host username isDarwin isNixOS; };
        home-manager.users.${username} = import ./home-manager/${host}/${os}-specific.nix;
      };

      nixosModule = { systemArc, host, ... }: nixpkgs.lib.nixosSystem {
        specialArgs = specialArgsFor (systems.nixos);
        modules = [
          sops-nix.nixosModules.sops
          ./hosts/${host}/config.nix
          inputs.distro-grub-themes.nixosModules.${systemArc}.default
          home-manager.nixosModules.home-manager
          homeManagerConfig
        ];
      };

      darwinModule = { systemArc, host, ... }: darwin.lib.darwinSystem {
        specialArgs = specialArgsFor (systems.macos);
        system = systemArc;
        modules = [
          sops-nix.darwinModules.sops
          ./hosts/${host}/config.nix
          home-manager.darwinModules.home-manager
          homeManagerConfig
        ];
      };

    in
    {
      nixosConfigurations = {
        ${systems.nixos.host} = nixosModule systems.nixos;
      };

      darwinConfigurations = {
        ${systems.macos.host} = darwinModule systems.macos;
      };
    };
}
