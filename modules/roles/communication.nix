{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.roles.communication;
in
{
  imports = [
    ../programs/weechat.nix
  ];

  options.jvf.roles.communication.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable communication tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.weechat.enable = true;

    environment.systemPackages = [
      pkgs.discord
    ];
  };
}
