# Alacritty config generator — pure function of preset
# Returns an attrset suitable for pkgs.formats.toml.generate.
{ lib }:
{ preset }:
let
  colors = preset.colors;
  fonts = preset.fonts;
in
{
  colors = {
    primary = {
      background = "0x${colors.background}";
      foreground = "0x${colors.foreground}";
    };
    cursor = {
      text = "0x${colors.background}";
      cursor = "0x${colors.cursor}";
    };
    normal = {
      black = "0x${colors.color0}";
      red = "0x${colors.color1}";
      green = "0x${colors.color2}";
      yellow = "0x${colors.color3}";
      blue = "0x${colors.color4}";
      magenta = "0x${colors.color5}";
      cyan = "0x${colors.color6}";
      white = "0x${colors.color7}";
    };
    bright = {
      black = "0x${colors.color8}";
      red = "0x${colors.color9}";
      green = "0x${colors.color10}";
      yellow = "0x${colors.color11}";
      blue = "0x${colors.color12}";
      magenta = "0x${colors.color13}";
      cyan = "0x${colors.color14}";
      white = "0x${colors.color15}";
    };
  };
  env = {
    TERM = "tmux-256color";
  };
  font = {
    size = fonts.size;
    normal = {
      family = "TamzenForPowerline";
      style = "Medium";
    };
    bold = {
      family = "TamzenForPowerline";
      style = "Bold";
    };
    italic = {
      family = "TamzenForPowerline";
      style = "Medium";
    };
    bold_italic = {
      family = "TamzenForPowerline";
      style = "Medium";
    };
  };
  scrolling = {
    history = 100000;
    multiplier = 3;
  };
  cursor = {
    blink_interval = 500;
    style = {
      shape = "Block";
      blinking = "Always";
    };
  };
}
