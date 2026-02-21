{ lib
, pkgs
, config
, username
, ...
}:
let
  cfg = config.jvf.desktop.hyprland.cava;

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
      gradient_color_1 = "'#4B4B4C'";
      gradient_color_2 = "'#657925'";
      gradient_color_3 = "'#7F878F'";
      gradient_color_4 = "'#A9A19B'";
      gradient_color_5 = "'#ECE5AF'";
      gradient_color_6 = "'#C8D0EC'";
      gradient_color_7 = "'#E1D7CF'";
      gradient_color_8 = "'#ECE5AF'";
    };
    smoothing = {
      noise_reduction = 77;
    };
  };
in
{
  options.jvf.desktop.hyprland.cava = {
    enable = lib.mkEnableOption "Cava - Console-based Audio Visualizer";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username to configure Cava for.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.cava = {
      packages = [
        pkgs.cava
      ];
      configs = {
        "cava.conf" = cavaConfig;
        "shaders" = ./shaders;
      };
    };
  };
}
