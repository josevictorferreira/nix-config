{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/ghostty.nix
    ../shared/chat.nix
    ./hyprland.nix
  ];

  home = {
    packages = with pkgs; [
      vlc
      font-manager
      obsidian
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
