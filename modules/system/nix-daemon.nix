# Aspect: system-nix-daemon
# Defines jvf.system.nix-daemon options and platform-specific nix daemon config.
# Both platforms: nix.settings, optimise, gc.
# NixOS only: programs.nix-ld.enable.
_:
let
  mkNixDaemonOptions =
    { lib, ... }:
    {
      options.jvf.system.nix-daemon = {
        autoOptimiseStore = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic store optimization by hard-linking identical files.";
        };

        garbageCollect = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic garbage collection.";
        };

        gcOptions = lib.mkOption {
          type = lib.types.str;
          default = "--delete-older-than 7d";
          description = "Options to pass to nix store gc command.";
        };

        experimentalFeatures = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "nix-command"
            "flakes"
          ];
          description = "Nix experimental features to enable.";
        };

        substituters = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "https://hyprland.cachix.org" ];
          description = "Additional binary cache substituters.";
        };

        trustedSubstituters = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "https://hyprland.cachix.org" ];
          description = "Trusted binary cache substituters.";
        };

        trustedPublicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
          description = "Public keys for trusted binary caches.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.nix-daemon;
    in
    {
      imports = [ mkNixDaemonOptions ];

      config = {
        nix = {
          settings = {
            experimental-features = cfg.experimentalFeatures;
            inherit (cfg) substituters;
            trusted-substituters = cfg.trustedSubstituters;
            trusted-public-keys = cfg.trustedPublicKeys;
            netrc-file = "/home/${config.jvf.core.username}/.netrc";
          };
          optimise = {
            automatic = cfg.autoOptimiseStore;
          };
          gc = lib.mkIf cfg.garbageCollect {
            automatic = true;
            options = cfg.gcOptions;
          };
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        programs.nix-ld.enable = true;
      };
    };
in
{
  flake.modules.nixos.system-nix-daemon = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-nix-daemon = mkConfig { isDarwin = true; };
}
