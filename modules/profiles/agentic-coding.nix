{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jvf.profiles.agenticCoding;
  scripts = (import ../common/ai-tools { inherit lib; }).scripts;
  bins = lib.mapAttrs (name: script: pkgs.writeShellScriptBin name script) scripts;
  binsList = lib.attrValues bins;
in
{
  imports = [
    ../programs/opencode
    ../programs/claudecode.nix
  ];

  options.jvf.profiles.agenticCoding.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable vibe coding tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.enable = true;
    jvf.programs.claudecode.enable = true;

    environment.systemPackages = [
      pkgs.code-cursor
      pkgs.cursor-cli
    ]
    ++ binsList;
  };
}
