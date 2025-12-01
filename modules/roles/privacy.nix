{
  lib,
  pkgs,
  config,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.roles.privacy;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.roles.privacy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable some privacy related tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {

    users.users."${cfg.username}".packages = lib.mkMerge (
      lib.optional (!isDarwin) [
        pkgs.protonmail-desktop
        pkgs.proton-pass
        pkgs.proton-authenticator
        pkgs.protonvpn-gui
      ]
    );
  };
}
