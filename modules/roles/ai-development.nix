{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.jvf.roles.aiDevelopment;
in
{
  imports = [
    ../programs/opencode
    ../programs/claudecode.nix
  ];

  options.jvf.roles.aiDevelopment = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable vibe coding tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.enable = true;
    jvf.programs.claudecode.enable = true;
    jvf.programs.droid.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.code-cursor
      pkgs.cursor-cli
      pkgs.goose-cli
    ]
    ++ lib.optional (!pkgs.stdenv.isDarwin) pkgs.llama-cpp-rocm
    ++ lib.optional (!pkgs.stdenv.isDarwin) pkgs.lmstudio;
  };
}
