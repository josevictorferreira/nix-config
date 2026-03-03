# k9s skin — theme-aware adapter
# Accepts config.jvf.theme.colors (hex, no #). Adds # prefix for k9s.
colors:
let
  c = name: "#${colors.${name}}";

  foreground = c "foreground";
  background = c "background";
  current_line = c "color3"; # yellow — closest to orange-brown highlight
  selection = c "color8"; # bright black — dark selection bg
  comment = c "color8"; # bright black — muted text
  cyan = c "color6";
  green = c "color2";
  yellow = c "color3";
  orange = c "color3"; # no dedicated orange in base16; use yellow
  magenta = c "color5";
  blue = c "color4";
  red = c "color1";
in
{
  body = {
    fgColor = foreground;
    bgColor = "default";
    logoColor = blue;
  };
  prompt = {
    fgColor = foreground;
    bgColor = background;
    suggestColor = orange;
  };
  info = {
    fgColor = magenta;
    sectionColor = foreground;
  };
  dialog = {
    fgColor = foreground;
    bgColor = "default";
    buttonFgColor = foreground;
    buttonBgColor = magenta;
    buttonFocusFgColor = background;
    buttonFocusBgColor = foreground;
    labelFgColor = comment;
    fieldFgColor = foreground;
  };
  frame = {
    border = {
      fgColor = selection;
      focusColor = foreground;
    };
    menu = {
      fgColor = foreground;
      keyColor = magenta;
      numKeyColor = magenta;
    };
    crumbs = {
      fgColor = background;
      bgColor = cyan;
      activeColor = yellow;
    };
    status = {
      newColor = magenta;
      modifyColor = blue;
      addColor = green;
      errorColor = red;
      highlightcolor = orange;
      killColor = comment;
      completedColor = comment;
    };
    title = {
      fgColor = foreground;
      bgColor = "default";
      highlightColor = blue;
      counterColor = magenta;
      filterColor = magenta;
    };
  };
  views = {
    charts = {
      bgColor = "default";
      defaultDialColors = [
        blue
        red
      ];
      defaultChartColors = [
        blue
        red
      ];
    };
    table = {
      fgColor = foreground;
      bgColor = "default";
      cursorFgColor = background;
      cursorBgColor = foreground;
      markColor = "darkgoldenrod";
      header = {
        fgColor = foreground;
        bgColor = "default";
        sorterColor = cyan;
      };
    };
    xray = {
      fgColor = foreground;
      bgColor = "default";
      cursorColor = current_line;
      graphicColor = blue;
      showIcons = true;
    };
    yaml = {
      keyColor = magenta;
      colonColor = blue;
      valueColor = foreground;
    };
    logs = {
      fgColor = foreground;
      bgColor = "default";
      indicator = {
        fgColor = foreground;
        bgColor = selection;
      };
    };
    help = {
      fgColor = foreground;
      bgColor = "default";
      indicator = {
        fgColor = red;
        bgColor = selection;
      };
    };
  };
}
