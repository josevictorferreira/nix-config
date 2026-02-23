# Aspect: system-nixpkgs
# Defines jvf.system.nixpkgs options and unfree package configuration.
# NixOS: nixpkgs.config with allowUnfree + predicate.
# Darwin: identical config (same nixpkgs.config structure).
{ ... }:
let
  mkNixpkgsOptions =
    { lib, ... }:
    {
      options.jvf.system.nixpkgs = {
        enable = lib.mkEnableOption "Nixpkgs unfree configuration" // {
          description = ''
            Whether to enable nixpkgs configuration for unfree packages.
            Allows installation of proprietary software like Steam.
          '';
        };

        allowUnfree = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Allow installation of unfree packages.";
        };

        allowedUnfreePackages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "steam"
            "steam-original"
            "steam-unwrapped"
            "steam-run"
          ];
          description = "List of unfree packages to allow by name.";
        };
      };
    };

  nixpkgsModule =
    { config, lib, ... }:
    let
      cfg = config.jvf.system.nixpkgs;
    in
    {
      imports = [ mkNixpkgsOptions ];

      config = lib.mkIf cfg.enable {
        nixpkgs.config = {
          allowUnfree = cfg.allowUnfree;
          allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowedUnfreePackages;
        };
      };
    };
in
{
  flake.modules.nixos.system-nixpkgs = nixpkgsModule;
  flake.modules.darwin.system-nixpkgs = nixpkgsModule;
}
