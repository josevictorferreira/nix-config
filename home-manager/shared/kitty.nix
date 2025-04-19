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
      settings = {
        include = "${config.home.homeDirectory}/.config/kitty/mocha.conf";
        shell = "${config.home.homeDirectory}/.config/kitty/tmux_session";
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
        background_opacity = 0.98;
        symbol_map = "U+1F000-U+1F999 Noto Color Emoji";
      };
      font = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
        size = 14;
      };
    };
    fonts.fontconfig.enable = true;
    home = {
      packages = [
        pkgs.kitty
        pkgs.timg
        pkgs.kitty-img
        pkgs.kitty-themes
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.noto-fonts
        pkgs.noto-fonts-emoji
      ];
      file = {
        ".config/kitty/mocha.conf" = {
          source = "${configRoot}/config/kitty/mocha.conf";
          recursive = true;
          executable = false;
        };
        ".config/kitty/latte.conf" = {
          source = "${configRoot}/config/kitty/latte.conf";
          recursive = true;
          executable = false;
        };
        ".config/kitty/tmux_session" = {
          source = "${configRoot}/config/kitty/tmux_session";
          recursive = true;
          executable = false;
        };
      };
    };
  };
}
