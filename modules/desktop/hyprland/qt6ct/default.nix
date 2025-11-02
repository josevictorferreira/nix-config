{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.qt6ct;
  qt6ctConf = {
    Appearance = {
      color_scheme_path = "${catpuccinMochaConfFile}";
      custom_palette = true;
      icon_theme = "Flat-Remix-Blue-Dark";
      standard_dialogs = "default";
      style = "kvantum";
    };
    Fonts = {
      fixed = "Fira Code Medium,12,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Regular";
      general = "Fira Code Medium,14,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Regular";
    };
    Interface = {
      activate_item_on_single_click = 1;
      buttonbox_layout = 0;
      cursor_flash_time = 1000;
      dialog_buttons_have_icons = 1;
      double_click_interval = 400;
      gui_effects = "General, AnimateMenu, AnimateCombo, AnimateTooltip, AnimateToolBox";
      keyboard_scheme = 2;
      menus_have_icons = true;
      show_shortcuts_in_context_menus = true;
      stylesheets = "@Invalid()";
      toolbutton_style = 4;
      underline_shortcut = 1;
      wheel_scroll_lines = 3;
    };
    SettingsWindow = {
      geometry = "@ByteArray(\\x1\\xd9\\xd0\\xcb\\0\\x3\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\x4\\xef\\0\\0\\x5_\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\t\\xff\\0\\0\\x5s\\0\\0\\0\\0\\x2\\0\\0\\0\\n\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\x4\\xef\\0\\0\\x5_)";
    };
    Troubleshooting = {
      force_raster_widgets = 1;
      ignored_applications = "@Invalid()";
    };
  };
  catpuccinLatte = {
    ColorScheme = {
      active_colors = "#ff4c4f69, #ffe6e9ef, #ff6c6f85, #ff7c7f93, #ffbcc0cc, #ff9ca0b0, #ff4c4f69, #ff4c4f69, #ff4c4f69, #ffeff1f5, #ffe6e9ef, #ff8c8fa1, #ff1e66f5, #ffeff1f5, #ff7287fd, #ffe64553, #ffeff1f5, #ff4c4f69, #ffdce0e8, #ff4c4f69, #808c8fa1";
      disabled_colors = "#ff6c6f85, #ffe6e9ef, #ff6c6f85, #ff7c7f93, #ffbcc0cc, #ff9ca0b0, #ff6c6f85, #ff6c6f85, #ff6c6f85, #ffeff1f5, #ffe6e9ef, #ff8c8fa1, #ff9ca0b0, #ff5c5f77, #ff7287fd, #ffe64553, #ffeff1f5, #ff4c4f69, #ffdce0e8, #ff4c4f69, #808c8fa1";
      inactive_colors = "#ff4c4f69, #ffe6e9ef, #ff6c6f85, #ff7c7f93, #ffbcc0cc, #ff9ca0b0, #ff4c4f69, #ff4c4f69, #ff4c4f69, #ffeff1f5, #ffe6e9ef, #ff8c8fa1, #ffccd0da, #ff6c6f85, #ff7287fd, #ffe64553, #ffeff1f5, #ff4c4f69, #ffdce0e8, #ff4c4f69, #808c8fa1";
    };
  };
  catpuccinMocha = {
    ColorScheme = {
      active_colors = "#ffcdd6f4, #ff1e1e2e, #ffa6adc8, #ff9399b2, #ff45475a, #ff6c7086, #ffcdd6f4, #ffcdd6f4, #ffcdd6f4, #ff1e1e2e, #ff181825, #ff7f849c, #ff89b4fa, #ff1e1e2e, #ff89b4fa, #fff38ba8, #ff1e1e2e, #ffcdd6f4, #ff11111b, #ffcdd6f4, #807f849c";
      disabled_colors = "#ffa6adc8, #ff1e1e2e, #ffa6adc8, #ff9399b2, #ff45475a, #ff6c7086, #ffa6adc8, #ffa6adc8, #ffa6adc8, #ff1e1e2e, #ff11111b, #ff7f849c, #ff89b4fa, #ff45475a, #ff89b4fa, #fff38ba8, #ff1e1e2e, #ffcdd6f4, #ff11111b, #ffcdd6f4, #807f849c";
      inactive_colors = "#ffcdd6f4, #ff1e1e2e, #ffa6adc8, #ff9399b2, #ff45475a, #ff6c7086, #ffcdd6f4, #ffcdd6f4, #ffcdd6f4, #ff1e1e2e, #ff181825, #ff7f849c, #ff89b4fa, #ffa6adc8, #ff89b4fa, #fff38ba8, #ff1e1e2e, #ffcdd6f4, #ff11111b, #ffcdd6f4, #807f849c";
    };
  };

  catpuccinMochaConfFile = pkgs.writeText "Catppuccin-Mocha.conf" (
    lib.generators.toINI { } catpuccinMocha
  );
  catpuccinLatteConfFile = pkgs.writeText "Catppuccin-Latte.conf" (
    lib.generators.toINI { } catpuccinLatte
  );
  qt6ctConfFile = pkgs.writeText "qt6ct.conf" (lib.generators.toINI { } qt6ctConf);

  qt6ctConfigDir = pkgs.runCommand "qt6ct-config-1.0.0" { } ''
    mkdir -p $out/qt6ct/colors
    ln -s ${qt6ctConfFile} $out/qt6ct/qt6ct.conf
    ln -s ${catpuccinMochaConfFile} $out/qt6ct/colors/Catppuccin-Mocha.conf
    ln -s ${catpuccinLatteConfFile} $out/qt6ct/colors/Catppuccin-Latte.conf
  '';

  qt6ctWrapper = pkgs.symlinkJoin {
    name = "qt6ct";
    paths = [
      pkgs.qt6ct
      pkgs.qt6.qtwayland
      pkgs.qt6Packages.qtstyleplugin-kvantum
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qt6ct \
        --prefix XDG_CONFIG_HOME : "${qt6ctConfigDir}"
    '';
  };
in
{
  options.jvf.desktop.hyprland.qt6ct = {
    enable = lib.mkEnableOption "qt6ct settings for Hyprland";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      qt6ctWrapper
    ];
  };
}
