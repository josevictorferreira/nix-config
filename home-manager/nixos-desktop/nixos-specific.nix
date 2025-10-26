{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/hyprland/default.nix
    ../shared/chat.nix
    ../shared/easyeffects.nix
  ];

  home = {
    packages = with pkgs; [
      vlc
      font-manager
      obsidian
      koreader
      dbeaver-bin
      libreoffice
      unetbootin
      nixos-generators

      discord
      spotifywm

      lmstudio

      inkscape-with-extensions
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
