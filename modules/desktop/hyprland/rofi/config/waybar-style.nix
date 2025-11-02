{
  config,
  pkgs,
  ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Main Config (waybar) */

  @import "${config.xdg.configHome}/rofi/master-config.rasi"

  /* ---- Configuration ---- */
  configuration {
    modi: "drun";
  }

  /* ---- Mainbox ---- */
  mainbox {
    children:
      [ "inputbar", "listview"];
  }

  entry {
    expand: true;
    placeholder: "🖼️  Choose Waybar Style";
  }

  /* ---- Listview ---- */
  listview {
    columns: 2;
    lines: 6;
  }
''
