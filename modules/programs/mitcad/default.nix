# Aspect: programs-mitcad
# MitCad parametric CAD (https://mitcad.org), packaged from the upstream AppImage.
# NixOS only: upstream ships just a .dmg for macOS.
_:
{
  flake.modules.nixos.programs-mitcad =
    { config, lib, pkgs, ... }:
    let
      cfg = config.jvf.programs.mitcad;

      pname = "mitcad";
      version = "0.56.0";

      src = pkgs.fetchurl {
        url = "https://github.com/mitcad/Mitcad/releases/download/v${version}/Mitcad-${version}-x86_64.AppImage";
        hash = "sha256-/EnFvbvMozOqig0My9owZM5Om6Qfl2fw5/15VRQqwcs=";
      };

      extracted = pkgs.appimageTools.extractType2 { inherit pname version src; };

      mitcad = pkgs.appimageTools.wrapType2 {
        inherit pname version src;
        extraInstallCommands = ''
          install -Dm444 ${extracted}/usr/share/applications/mitcad.desktop -t $out/share/applications
          cp -r ${extracted}/usr/share/icons $out/share/icons
        '';
        meta = {
          description = "Open-source parametric CAD with a design history";
          homepage = "https://mitcad.org";
          license = lib.licenses.mit;
          platforms = [ "x86_64-linux" ];
          mainProgram = "mitcad";
        };
      };
    in
    {
      options.jvf.programs.mitcad.username = lib.mkOption {
        type = lib.types.str;
        default = config.jvf.core.username;
      };

      config.users.users.${cfg.username}.packages = [ mitcad ];
    };
}
