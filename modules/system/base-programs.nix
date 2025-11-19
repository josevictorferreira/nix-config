{
  config,
  lib,
  pkgs,
  options,
  system,
  ...
}:

let
  cfg = config.jvf.system.base-programs;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.base-programs = {
    enable = lib.mkEnableOption "base system programs configuration" // {
      description = ''
        Whether to enable configuration for basic system programs.
        Configures:
        - nix-ld (automatic dynamic linking)
        - dconf (application settings)
        - seahorse (GNOME keyring client)
        - gnupg agent with SSH support
        - network-manager applet
        - FUSE with user other permissions
        - MTR network diagnostic
      '';
    };
  };

  config =
    lib.mkIf cfg.enable {
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    }
    // lib.optionalAttrs (!isDarwin) {
      programs.nix-ld = {
        enable = true;
        libraries = options.programs.nix-ld.libraries.default;
      };
      programs.nm-applet.indicator = true;
      programs.mtr.enable = true;
      programs.dconf.enable = true;
      programs.seahorse.enable = true;
      programs.fuse.userAllowOther = true;
    };
}
