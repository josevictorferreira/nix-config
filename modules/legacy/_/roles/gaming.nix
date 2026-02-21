{
  lib,
  pkgs,
  config,
  system,
  ...
}:

let
  cfg = config.jvf.roles.gaming;
  # NOTE: uses `system` arg (not pkgs.stdenv.isDarwin) because isDarwin
  # is referenced in `imports` which is evaluated before pkgs is available.
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports = if !isDarwin then [ ../programs/steam.nix ] else [ ];

  options.jvf.roles.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable gaming tools and platforms.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable (
    {
      users.users."${cfg.username}".packages = [
        pkgs.lutris

        pkgs.wine64
        pkgs.winetricks
        pkgs.wine-wayland

        pkgs.vinegar
      ];
    }
    // (
      if !isDarwin then
        {
          jvf.programs.steam.enable = true;
        }
      else
        { }
    )
  );
}
