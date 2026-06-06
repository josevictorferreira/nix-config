# kitty.conf generator — pure function of preset
# Returns a kitty.conf string with default settings + theme colors.
{ lib }:
{ preset }:
let
  colors = preset.colors;
  fonts = preset.fonts;

  toConfigFormat =
    settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (
          key: value:
          if builtins.isBool value then
            "${key} ${if value then "yes" else "no"}"
          else
            "${key} ${toString value}"
        )
        settings
    );

  defaultSettings = {
    bold_font = "JetBrainsMonoNL Nerd Font Bold";
    italic_font = "JetBrainsMonoNL Nerd Font Italic";
    bold_italic_font = "JetBrainsMonoNL Nerd Font Bold Italic";
    disable_ligatures = "never";
    window_border_width = "0.0pt";
    window_margin_width = 0;
    draw_minimal_borders = true;
    window_padding_width = 0;
    single_window_margin_width = -1;
    confirm_os_window_close = 0;
    placement_strategy = "top-left";
    repaint_delay = 2;
    input_delay = 0;
    sync_to_monitor = false;
    wayland_enable_ime = false;
    term = "xterm-256color";
    background_opacity = "0.95";
    cursor_trail = 1;
    cursor_trail_decay = "0.1 0.2";
    cursor_trail_start_threshold = 4;
  };

  colorIndices = lib.genList lib.id 16;

  themeOverrides = {
    font_family = fonts.monospace;
    font_size = fonts.size;
    background = "#${colors.background}";
    foreground = "#${colors.foreground}";
    cursor = "#${colors.cursor}";
    cursor_trail_color = "#${colors.cursor}";
  }
  // lib.listToAttrs (
    map
      (
        i: lib.nameValuePair "color${toString i}" "#${lib.getAttr "color${toString i}" colors}"
      )
      colorIndices
  );
in
toConfigFormat (defaultSettings // themeOverrides)
