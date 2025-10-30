{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/hyprland/default.nix
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

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
