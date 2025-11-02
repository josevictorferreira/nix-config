{
  config,
  pkgs,
  ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Main Config - emoji */

  @import "${config.xdg.configHome}/rofi/master-config.rasi"

  /* ---- Entry ---- */
  entry {
    width: 37%;
    placeholder: "💫 Search Emoji's  **note** 👀 Click or Return to choose | Ctrl V to Paste";
  }

  /* ---- Listview ---- */
  listview {
    columns: 1;
    lines: 8;
  }
''
