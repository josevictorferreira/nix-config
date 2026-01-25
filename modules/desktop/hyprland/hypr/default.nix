{ lib
, pkgs
, config
, username
, inputs
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.hypr;
in
{
  options.jvf.desktop.hyprland.hypr = {
    enable = lib.mkEnableOption "Hyprland with JVF configurations.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hypridle.enable = false;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.overrideAttrs (oldAttrs: {
        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          "-DNO_HYPRPM=ON"
        ];
      });
    };

    jvf.wrappers.users.${cfg.username}.programs.hypr = {
      packages = [
        pkgs.hypridle
        pkgs.hyprcursor
        pkgs.hyprlock
        pkgs.pyprland
      ];
      configs = {
        "hypr" = ./.;
      };
      postInstall = ''
        echo "Reloading Hyprland..."
        ${config.programs.hyprland.package}/bin/hyprctl reload || true
      '';
    };

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
  };
}
