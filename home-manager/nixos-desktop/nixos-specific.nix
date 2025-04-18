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
      font-manager
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
