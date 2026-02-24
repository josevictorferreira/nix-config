# TokyoNight skin for k9s
# Pure data export - no module boilerplate
{ }:
let
  foreground = "#c0caf5";
  background = "#24283b";
  current_line = "#8c6c3e";
  selection = "#364a82";
  comment = "#565f89";
  cyan = "#7dcfff";
  green = "#9ece6a";
  yellow = "#e0af68";
  orange = "#ff9e64";
  magenta = "#bb9af7";
  blue = "#7aa2f7";
  red = "#f7768e";
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
