{ config
, pkgs
, ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Main Config - For Keybinds generation */

  @import "/etc/xdg/rofi/master-config.rasi"

  /* ---- Entry ---- */
  entry {
    width: 80%;
    placeholder: " 🧮 Search Keybinds      ☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function";
  }

  /* ---- Listview ---- */
  listview {
    columns: 2;
    lines: 12;
  }

  window {
      width: 90%;
  }
''
