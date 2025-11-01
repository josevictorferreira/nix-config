{
  configRoot,
  lib,
  pkgs,
  ...
}:

let
  username = "josevictor";
in
{
  imports = [
    ./modules/desktop/hyprland/ags/default.nix
  ];

  options.test-config = {
    enable = lib.mkEnableOption "Test AGS configuration";
  };

  config = {
    users.defaultUser = username;
    test-config.enable = true;
  };
}
