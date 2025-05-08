{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/hyprland/default.nix
    ../shared/ghostty.nix
    ../shared/chat.nix
  ];

  home = {
    packages = with pkgs; [
      vlc
      font-manager
      obsidian
      spotify
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
