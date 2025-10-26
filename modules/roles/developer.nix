{
  lib,
  pkgs,
  config,
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
  ];

  options.jvf.roles.developer.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable developer tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.ghostty.enable = true;
    jvf.programs.alacritty.enable = true;
    jvf.programs.kitty.enable = true;

    environment.systemPackages = [
      pkgs.gitleaks
    ];
  };
}
