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
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      sops-nix,
      home-manager,
      ...
    }:
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
          isDarwin,
          isNixOS,
        }:
        let
          pkgs = mkPkgs systemArc;
          homeDir =
            if (builtins.match ".*darwin.*" systemArc) != null then
              "/Users/${username}"
            else
              "/home/${username}";
        in
        {
          inherit
            inputs
            os
            systemArc
            username
            host
            isDarwin
            isNixOS
            homeDir
            ;
          configRoot = ./.;
          jvfLib = import ./lib {
            lib = pkgs.lib;
            inherit pkgs;
          };
        };

      homeManagerConfig =
        {
          systemArc,
          os,
          host,
          username,
          isDarwin,
          isNixOS,
          ...
        }:
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = specialArgsFor {
            inherit
              systemArc
              os
              host
              username
              isDarwin
              isNixOS
              ;
          };
          home-manager.users.${username} = import ./home-manager/${host}/nixos-specific.nix;
        };

      nixosModule =
        { systemArc, host, ... }:
        nixpkgs.lib.nixosSystem {
          specialArgs = specialArgsFor (systems.nixos);
          modules = [
            sops-nix.nixosModules.sops
            ./modules/users/repositories.nix
            ./hosts/${host}/config.nix
            inputs.distro-grub-themes.nixosModules.${systemArc}.default
            home-manager.nixosModules.home-manager
            homeManagerConfig
          ];
        };

      darwinModule =
        { systemArc, host, ... }:
        darwin.lib.darwinSystem {
          specialArgs = specialArgsFor (systems.macos);
          system = systemArc;
          modules = [
            sops-nix.darwinModules.sops
            ./modules/users/repositories.nix
            ./hosts/${host}/config.nix
            home-manager.darwinModules.home-manager
            homeManagerConfig
          ];
        };

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

    in
    {
      nixosConfigurations = {
        ${systems.nixos.host} = nixosModule systems.nixos;
      };

      darwinConfigurations = {
        ${systems.macos.host} = darwinModule systems.macos;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          jvfLib = import ./lib {
            lib = pkgs.lib;
            inherit pkgs;
            fetchFromGitHub = pkgs.fetchFromGitHub;
          };
        in
        {
          # Packages can be defined here if needed
          # Example: some-package = pkgs.callPackage ./pkgs/some-package {};
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
