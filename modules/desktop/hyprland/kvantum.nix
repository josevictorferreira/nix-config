# Aspect: desktop-hyprland-kvantum (NixOS only)
# Kvantum theme engine for Qt apps in Hyprland.
# Profile artifacts: dark/light Kvantum configs for runtime theme switching.
_: {
  flake.modules.nixos.desktop-hyprland-kvantum =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.kvantum;

      # Generate a complete Kvantum directory for a given theme name.
      # Includes all theme subdirectories from assets plus a profile-specific kvconfig.
      mkKvantumDir =
        themeName:
        let
          kvconfig = pkgs.writeText "kvantum.kvconfig" ''
            [General]
            theme=${themeName}
          '';
        in
        pkgs.runCommand "kvantum-${themeName}" { } ''
          mkdir -p $out
          cp -r ${./assets/kvantum/Catppuccin-Mocha} $out/Catppuccin-Mocha
          cp -r ${./assets/kvantum/Catppuccin-Latte} $out/Catppuccin-Latte
          cp ${kvconfig} $out/kvantum.kvconfig
        '';

      # Profile artifacts for dual-theme runtime switching
      darkKvantumArtifact = mkKvantumDir "Catppuccin-Mocha";
      lightKvantumArtifact = mkKvantumDir "Catppuccin-Latte";
    in
    {
      options.jvf.desktop.hyprland.kvantum = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure Kvantum";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.Kvantum.packages = [
          pkgs.libsForQt5.qtstyleplugin-kvantum
          pkgs.qt6Packages.qtstyleplugin-kvantum
        ];
        jvf.home.users.${cfg.username}.items.".config/Kvantum" = {
          kind = "dir";
          mode = "copy";
          source = ./assets/kvantum;
        };

        # Profile artifacts for dual-theme runtime switching
        jvf.theme.profileArtifacts.dark.kvantum = darkKvantumArtifact;
        jvf.theme.profileArtifacts.light.kvantum = lightKvantumArtifact;
      };
    };
}
