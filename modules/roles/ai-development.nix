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
    ../common/ai-tools/default.nix
    ../programs/ck-search.nix
    ../programs/opencode
    ../programs/claudecode.nix
    ../programs/droid.nix
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
    jvf.programs."ck-search".enable = true;
    jvf.programs.opencode.enable = true;
    jvf.programs.claudecode.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.code-cursor
      pkgs.cursor-cli
      pkgs.goose-cli
    ];
  };
}
