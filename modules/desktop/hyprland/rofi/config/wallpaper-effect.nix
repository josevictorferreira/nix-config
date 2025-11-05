{ config
, pkgs
, ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Wallpaper Effects */

  @import "/etc/xdg/rofi/master-config.rasi"

  /* ---- Entry ---- */
  entry {
    width: 20%;
    placeholder: "🏙️ Choose desired wallpaper effect";
  }

  /* ---- Window ---- */
  window {
    width: 24%;
  }

  /* ---- Listview ---- */
  listview {
    fixed-columns: false;
    colums: 2;
    lines: 8;
  }

  /* ---- Inputbar ---- */
  inputbar {
      background-image: url("~/.config/hypr/wallpaper_effects/.wallpaper_modified", width);
  }
''
