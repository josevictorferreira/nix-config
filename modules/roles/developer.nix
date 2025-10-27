{
  lib,
  pkgs,
  config,
  systemArc,
  ...
}:

let
  cfg = config.jvf.roles.developer;
in
{
  imports = [
    ../programs/ghostty.nix
    ../programs/alacritty.nix
    ../programs/kitty.nix
    ../programs/git.nix
  ];

  options.jvf.roles.developer.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable developer tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.ghostty.enable = !(lib.strings.hasInfix "darwin" systemArc);
    jvf.programs.alacritty.enable = true;
    jvf.programs.kitty.enable = true;
    jvf.programs.git = {
      enable = true;
      userName = "Jose Victor Ferreira";
      userEmail = "root@josevictor.me";
    };

    environment.systemPackages = [
      pkgs.gitleaks
      pkgs.difftastic
      pkgs.yq
    ];
  };
}
