{
  config,
  pkgs,
  ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Clipboard Config - Clipboard */

  @import "${config.xdg.configHome}/rofi/master-config.rasi"

  /* ---- Entry ---- */
  entry {
    width: 37%;
    placeholder: "📋 Search Clipboard **note** 👀 CTRL Del - Cliphist del or Alt Del - cliphist wipe";
  }

  /* ---- Listview ---- */
  listview {
    columns: 1;
    lines: 8;
  }
''
