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

        atticPushCache = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "homelab";
          description = ''
            Name of an Attic cache to push every locally built path to via a
            post-build-hook. Requires `attic login` to have been run for the
            primary user. Null disables the hook.
          '';
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, pkgs, ... }:
    let
      cfg = config.jvf.system.nix-daemon;

      # The nix daemon runs post-build hooks as root, so attic would look for
      # its token in root's home; point it at the primary user's config. The
      # hook must never fail or stall a build, hence the timeout and exit 0.
      atticPushHook = pkgs.writeShellScript "attic-push-hook" ''
        set -f # $OUT_PATHS is space-separated; never glob it
        export IFS=' '
        export HOME="/home/${config.jvf.core.username}"
        export XDG_CONFIG_HOME="$HOME/.config"

        if [ -n "$OUT_PATHS" ]; then
          ${pkgs.coreutils}/bin/timeout 30m \
            ${pkgs.attic-client}/bin/attic push ${toString cfg.atticPushCache} $OUT_PATHS \
            || echo "attic-push-hook: push failed, continuing" >&2
        fi

        exit 0
      '';
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
            # Keep dev-shell/build-time deps across GC so direnv shells
            # and repeated builds don't re-download after every collection.
            keep-outputs = true;
            keep-derivations = true;
            # Let remote builders fetch deps from caches instead of
            # copying everything from this machine.
            builders-use-substitutes = true;
          }
          // lib.optionalAttrs (cfg.atticPushCache != null) {
            post-build-hook = atticPushHook;
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
        # CLI for pushing to the self-hosted Attic binary cache (homelab).
        environment.systemPackages = [ pkgs.attic-client ];
      };
    };
in
{
  flake.modules.nixos.system-nix-daemon = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-nix-daemon = mkConfig { isDarwin = true; };
}
