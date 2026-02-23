# Aspect: roles-media
# Bundles media creation and playback tools.
# Enables easyeffects (NixOS only) and installs media packages.
{ ... }:
let
  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.media = {
        enable = lib.mkEnableOption "media tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.media;

      commonPackages = [
        pkgs.ffmpeg
        (pkgs.mpv.override { scripts = [ pkgs.mpvScripts.mpris ]; })
      ];

      linuxPackages = [
        pkgs.inkscape-with-extensions
        pkgs.vlc
        pkgs.spotifywm
        pkgs.hplip
      ];
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs.easyeffects.enable = !isDarwin;

        users.users."${cfg.username}".packages =
          commonPackages ++ (lib.optionals (!isDarwin) linuxPackages);
      };
    };
in
{
  flake.modules.nixos.roles-media = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-media = mkConfig { isDarwin = true; };
}
