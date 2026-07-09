# Aspect: system-nixpkgs
# Defines jvf.system.nixpkgs options and unfree package configuration.
# NixOS: nixpkgs.config with allowUnfree + predicate.
# Darwin: identical config (same nixpkgs.config structure).
_:
let
  mkNixpkgsOptions =
    { lib, ... }:
    {
      options.jvf.system.nixpkgs = {
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
            "google-chrome"
            "chromium"
            "code-cursor"
            "cursor-cli"
            "keymapp"
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

      config = {
        nixpkgs.config = {
          inherit (cfg) allowUnfree;
          allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowedUnfreePackages;
        };
      };
    };
in
{
  flake.modules.nixos.system-nixpkgs = nixpkgsModule;
  flake.modules.darwin.system-nixpkgs = nixpkgsModule;
}
