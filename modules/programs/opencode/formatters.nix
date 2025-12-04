{ lib, pkgs, ... }:
{
  config.jvf.programs.opencode.settings.formatter = {
    nixfmt = {
      command = [
        (lib.getExe pkgs.nixpkgs-fmt)
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

    rubocop = {
      command = [
        "bundle"
        "exec"
        "rubocop"
      ];
      extensions = [
        ".rb"
        "Gemfile"
        ".gemspec"
        ".ru"
        ".rake"
        ".rbs"
      ];
    };
  };
}
