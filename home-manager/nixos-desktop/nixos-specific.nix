{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/hyprland/default.nix
    ../shared/ghostty.nix
    ../shared/chat.nix
    ../shared/easyeffects.nix
  ];

  home = {
    packages = with pkgs; [
      vlc
      font-manager
      obsidian
      spotify
      koreader
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
