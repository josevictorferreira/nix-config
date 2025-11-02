{
  config,
  pkgs,
  ...
}:
''
  /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
  /* Main Config (compact) */

  @import "${config.xdg.configHome}/rofi/master-config.rasi"

  /* ---- Configuration ---- */
  configuration {
    modi: "drun";
  }

  /* ---- Window ---- */
  window {
    width: 50%;
    border-radius: 15px;
  }

  /* ---- Inputbar ---- */
  inputbar {
    background-image: url("${config.xdg.configHome}/rofi/.current_wallpaper", width);
  }

  /* ---- Imagebox ---- */
  imagebox {
    orientation: vertical;
    children: [ "entry", "listview"];
  }

  /* ---- Entry input ---- */
  entry {
    width: 23%;
    placeholder: "👀  View / Edit Hyprland Configs";
  }

  /* ---- Listview ---- */
  listview {
    columns: 2;
    lines: 6;
    spacing: 4px;
    border-radius: 12px;
  }

  /* ---- Element ---- */
  element {
    border-radius: 10px;
  }
''
