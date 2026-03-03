# Aspect: system-base-programs
# Defines jvf.system.base-programs options and platform-specific program config.
# NixOS: gnupg agent, nm-applet, mtr, dconf, seahorse, fuse.
# Darwin: gnupg agent only.
_:
let
  mkBaseProgramsOptions =
    _:
    {
      options.jvf.system.base-programs = { };
    };

  mkConfig =
    { isDarwin }:
    { lib, ... }:
    {
      imports = [ mkBaseProgramsOptions ];

      config = {
        programs.gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        programs.nm-applet.indicator = true;
        programs.mtr.enable = true;
        programs.dconf.enable = true;
        programs.seahorse.enable = false;
        programs.fuse.userAllowOther = true;
      };
    };
in
{
  flake.modules.nixos.system-base-programs = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-base-programs = mkConfig { isDarwin = true; };
}
