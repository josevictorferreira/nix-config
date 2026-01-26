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

    dockerfmt = {
      command = [
        (lib.getExe pkgs.dockerfmt)
      ];
      extensions = [
        ".dockerfile"
        "Dockerfile"
        "Containerfile"
        "*Dockerfile*"
        "*Containerfile*"
      ];
    };

    rubocop = {
      command = [
        "bundle"
        "exec"
        "rubocop"
        "-A"
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
