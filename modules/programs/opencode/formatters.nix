{ lib, pkgs, ... }:
{
  config.jvf.programs.opencode.settings.formatter = {
    nixfmt = {
      command = [
        (lib.getExe pkgs.nixfmt)
        "$FILE"
      ];
      extensions = [ ".nix" ];
    };

    rustfmt = {
      command = [
        (lib.getExe pkgs.rustfmt)
        "$FILE"
      ];
      extensions = [ ".rs" ];
    };
  };
}
