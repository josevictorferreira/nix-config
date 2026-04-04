# Aspect: desktop-hyprland-cava (NixOS only)
# Cava - Console-based Audio Visualizer for Hyprland.
_: {
  flake.modules.nixos.desktop-hyprland-cava =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.cava;
      colors = config.jvf.theme.colors;

      cavaConfig = {
        general = {
          framerate = 60;
          autosens = 1;
          sensitivity = 100;
          bars = 0;
          bar_width = 2;
          bar_spacing = 1;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
        };
        input = {
          method = "pipewire";
          source = "auto";
        };
        output = {
          method = "noncurses";
          channels = "stereo";
        };
        color = {
          gradient = 1;
          gradient_count = 8;
          gradient_color_1 = "'#${colors.color1}'";
          gradient_color_2 = "'#${colors.color3}'";
          gradient_color_3 = "'#${colors.color2}'";
          gradient_color_4 = "'#${colors.color6}'";
          gradient_color_5 = "'#${colors.color4}'";
          gradient_color_6 = "'#${colors.color5}'";
          gradient_color_7 = "'#${colors.color1}'";
          gradient_color_8 = "'#${colors.color3}'";
        };
        smoothing = {
          noise_reduction = 77;
        };
      };
      cavaConfigDir = pkgs.linkFarm "cava-config" [
        {
          name = "cava.conf";
          path = pkgs.writeText "cava.conf" (lib.generators.toINI { } cavaConfig);
        }
        {
          name = "shaders";
          path = ./assets/cava/shaders;
        }
      ];
    in
    {
      options.jvf.desktop.hyprland.cava = {

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username to configure Cava for.";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.cava = {
          packages = [
            pkgs.cava
          ];
        };

        jvf.home.users.${cfg.username}.items.".config/cava" = {
          kind = "dir";
          mode = "copy";
          source = cavaConfigDir;
        };
      };
    };
}
