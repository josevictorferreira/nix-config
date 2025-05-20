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
    ];
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
