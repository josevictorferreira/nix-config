{
  config,
  pkgs,
  ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Main config Rofi Beats Config (compact) */

  @import "/etc/xdg/rofi/master-config.rasi"

  /* ---- Entry ---- */
  entry {
    width: 20%;
    placeholder: "📻 Choose Music Source";
  }

  /* ---- Window ---- */
  window {
    width: 24%;
  }

  /* ---- Listview ---- */
  listview {
    fixed-columns: false;
    colums: 1;
    lines: 3;
  }
''
