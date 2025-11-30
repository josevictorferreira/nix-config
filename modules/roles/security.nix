{
  lib,
  pkgs,
  config,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.roles.security;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.roles.security = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable some security related tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable (
    {
    }
    // (lib.optionalAttrs (!isDarwin) {
      users.users."${cfg.username}".packages = [
        pkgs.protonmail-desktop
        pkgs.proton-pass
        pkgs.proton-authenticator
        pkgs.protonvpn-gui
      ];
    })
  );
}
