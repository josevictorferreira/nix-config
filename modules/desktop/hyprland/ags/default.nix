{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.ags;

  agsConfig = pkgs.stdenv.mkDerivation {
    pname = "ags-config";
    version = "1.0.0";

    src = lib.cleanSourceWith {
      src = ./.;
      filter = path: type: (baseNameOf path) != "default.nix";
    };

    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };

  agsWrapper = pkgs.writeShellApplication {
    name = "ags";
    runtimeInputs = [ cfg.package ];

    text = ''
      exec ${cfg.package}/bin/ags --config ${agsConfig}/config.js "$@"
    '';
  };

in
{
  options.jvf.desktop.hyprland.ags = {
    enable = lib.mkEnableOption "AGS - Awesome Hyprland Widgets";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ags;
      description = "The AGS package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ agsWrapper ];
  };
}
