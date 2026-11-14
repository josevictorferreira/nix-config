# Aspect: programs-easyeffects
# Installs easyeffects and materializes ~/.config/easyeffects from the
# .easyeffects config repo, pinned via the easyeffects-config flake input and
# copied by jvf.home (copy mode so easyeffects can keep writing runtime state).
# Runtime state dirs (db/, autoload/, irs/, rnnoise/) are preserved across
# rebuilds. To pick up config changes: push upstream, `nix flake update
# easyeffects-config`, rebuild.
{ lib, ... }:
let
  mkOptions =
    { config, ... }:
    {
      username = lib.mkOption {
        type = lib.types.str;
        default = config.jvf.core.username;
        description = "Username for which to install the configuration";
      };
    };

  easyeffectsModule =
    { config, pkgs, inputs, ... }:
    let
      cfg = config.jvf.programs.easyeffects;
    in
    {
      options.jvf.programs.easyeffects = mkOptions { inherit config; };

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.easyeffects
        ];

        jvf.home.users.${cfg.username}.items.".config/easyeffects" = {
          kind = "dir";
          mode = "copy";
          source = inputs.easyeffects-config;
          preserve = [
            "db"
            "autoload"
            "irs"
            "rnnoise"
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-easyeffects = easyeffectsModule;
  flake.modules.darwin.programs-easyeffects = easyeffectsModule;
}
