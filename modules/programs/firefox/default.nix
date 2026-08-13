# Aspect: programs-firefox
# Installs Firefox to the user profile. No policies or prefs are set here;
# Wayland/Ozone hinting is already handled globally (see jvf.system.environment).
{ ... }:
let
  firefoxModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.firefox;
    in
    {
      options.jvf.programs.firefox.username = lib.mkOption {
        type = lib.types.str;
        default = config.jvf.core.username;
        description = "Username for which to install Firefox";
      };

      config = {
        users.users."${cfg.username}".packages = [ pkgs.firefox ];
      };
    };
in
{
  flake.modules.nixos.programs-firefox = firefoxModule;
  flake.modules.darwin.programs-firefox = firefoxModule;
}
