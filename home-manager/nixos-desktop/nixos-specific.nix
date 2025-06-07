{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/hyprland/default.nix
    ../shared/ghostty.nix
    ../shared/chat.nix
    ../shared/easyeffects.nix
    ../shared/adaptive-brightness.nix
  ];

  home = {
    packages = with pkgs; [
      vlc
      font-manager
      obsidian
      spotify
      koreader
      dbeaver-bin
      libreoffice
      xdg-utils
    ];

    file.".config/mimeapps.list".text = ''
      [Default Applications]
      text/x-lua=org.xfce.mousepad.desktop
      application/octet-stream=vlc.desktop
      text/csv=calc.desktop
      inode/directory=Thunar.desktop

      [Added Associations]
      text/x-lua=org.xfce.mousepad.desktop;nvim.desktop;
      application/vnd.microsoft.portable-executable=wine.desktop;
      image/svg+xml=org.xfce.mousepad.desktop;
      text/csv=org.xfce.mousepad.desktop;calc.desktop;
      text/plain=org.xfce.mousepad.desktop;
      application/x-msdownload=wine.desktop;org.gnome.FileRoller.desktop;
      application/octet-stream=vlc.desktop;
      application/json=org.gnome.FileRoller.desktop;
    '';
  };

  modules = {
    easyeffects = {
      enable = true;
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
