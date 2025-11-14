{ config, lib, pkgs, options, ... }:

let
  cfg = config.jvf.system.base-programs;
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

  config = lib.mkIf cfg.enable {
    # nix-ld for automatic dynamic linking
    programs.nix-ld = {
      enable = true;
      libraries = options.programs.nix-ld.libraries.default;
    };

    # Network manager applet
    programs.nm-applet.indicator = true;

    # Application settings storage
    programs.dconf.enable = true;

    # GNOME keyring interface
    programs.seahorse.enable = true;

    # FUSE utilities for user filesystems
    programs.fuse.userAllowOther = true;

    # Network diagnostics
    programs.mtr.enable = true;

    # GPG agent with SSH support
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
