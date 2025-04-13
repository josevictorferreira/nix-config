{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ../shared/ghostty.nix
    ./hyprland.nix
  ];

  home = {
    packages = with pkgs; [
      vlc
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
