# Aspect: roles-media
# Bundles media creation and playback tools.
# Imports easyeffects (NixOS only) and installs media packages.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.media = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    { config
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
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-easyeffects
      ]);

      config = {
        users.users."${cfg.username}".packages = commonPackages ++ linuxPackages;
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.media;

      commonPackages = [
        pkgs.ffmpeg
        (pkgs.mpv.override { scripts = [ pkgs.mpvScripts.mpris ]; })
      ];
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = commonPackages;
      };
    };
in
{
  flake.modules.nixos.roles-media = nixosModule;
  flake.modules.darwin.roles-media = darwinModule;
}
