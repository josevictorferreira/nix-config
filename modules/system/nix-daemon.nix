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
            Name of an Attic cache to push new store paths to from a background
            `attic watch-store` service (NixOS only). Requires `attic login` to
            have been run for the primary user. Null disables the service.
          '';
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, pkgs, ... }:
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
            # Keep dev-shell/build-time deps across GC so direnv shells
            # and repeated builds don't re-download after every collection.
            keep-outputs = true;
            keep-derivations = true;
            # Let remote builders fetch deps from caches instead of
            # copying everything from this machine.
            builders-use-substitutes = true;
            # The homelab cache is a LAN host that is often down. Without
            # `fallback`, an unreachable substituter is a hard error; with it,
            # Nix logs a warning and moves on to the next cache or builds
            # locally. `connect-timeout` bounds how long a dead host can stall
            # each attempt (the default is curl's 300 seconds).
            fallback = true;
            connect-timeout = 5;
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

        # Upload new store paths in the background. A post-build-hook runs
        # synchronously and stalls the build loop on every slow upload;
        # watch-store decouples pushing from building entirely. Runs as the
        # primary user so attic finds its token in ~/.config/attic.
        systemd.services.attic-watch-store = lib.mkIf (cfg.atticPushCache != null) {
          description = "Push new Nix store paths to the Attic cache";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            User = config.jvf.core.username;
            ExecStart = "${pkgs.attic-client}/bin/attic watch-store ${cfg.atticPushCache}";
            # The homelab cache is often down; keep retrying instead of giving up.
            Restart = "always";
            RestartSec = 30;
            Nice = 10;
            IOSchedulingClass = "idle";
          };
        };
      };
    };
in
{
  flake.modules.nixos.system-nix-daemon = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-nix-daemon = mkConfig { isDarwin = true; };
}
