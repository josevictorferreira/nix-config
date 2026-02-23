# config/formatter.nix - Formatter configurations for OpenCode
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.jvf.programs.opencode;
in
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

    ruff = {
      command = [
        "uv"
        "run"
        "ruff"
        "check"
        "--fix"
      ];
      extensions = [
        ".py"
        ".pyi"
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
