{ pkgs, lib, config, configRoot, ... }:

with lib;
let
  cfg = config.modules.kitty;
in
{
  options.modules.kitty = {
    enable = mkEnableOption "kitty";
  };
  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      darwinLaunchOptions = [
        "--single-instance"
      ];
      settings = {
        include = "${config.home.homeDirectory}/.config/kitty/themes/mocha.conf";
        shell = "${config.home.homeDirectory}/.config/kitty/scripts/tmux_session";
        disable_ligadures = "never";
        window_border_width = 0;
        window_margin_width = 0;
        draw_minimal_borders = true;
        window_padding_width = 0;
        single_window_margin_width = -1;
        confirm_os_window_close = 0;
        placement_strategy = "center";
        repaint_delay = 2;
        input_delay = 0;
        sync_to_monitor = false;
        wayland_enable_ime = false;
        term = "tmux-256color";
        background_opacity = 0.999;
        symbol_map = "U+1F000-U+1F999 Noto Color Emoji";
        cursor = "#FF9800";
        cursor_text_color = "#1E1E2E";
        cursor_shape = "block";
        cursor_blink_interval = "0.5";
        cursor_stop_blinking_after = "0";
        cursor_trail = "1";
        enable_audio_bell = "no";
        visual_bell_duration = "0.1";
        window_alert_on_bell = "yes";
      };
      font = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
        size = 11;
      };
    };
    fonts.fontconfig.enable = true;
    home = {
      packages = [
        pkgs.kitty
        pkgs.kitty.terminfo
        pkgs.timg
        pkgs.kitty-img
        pkgs.kitty-themes
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.noto-fonts
        pkgs.noto-fonts-emoji
      ];
      file = {
        ".config/kitty/themes/" = {
          source = "${configRoot}/config/kitty/themes/";
          recursive = true;
          executable = false;
        };
        ".config/kitty/scripts/" = {
          source = "${configRoot}/config/kitty/scripts/";
          recursive = true;
          executable = false;
        };
      };
    };
  };
}
