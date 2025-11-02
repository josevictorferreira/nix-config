{
  config,
  pkgs,
  ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Rofi Beats Config (compact) */

  @import "/etc/xdg/rofi/config-compact.rasi"

  /* ---- Entry ---- */
  entry {
    placeholder: "📻 Choose Media or Stations to play";
  }

  /* ---- Listview ---- */
  listview {
    lines: 7;
  }
''
