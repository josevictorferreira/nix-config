{ pkgs, ... }:

{
  imports = [
    ../shared/default.nix
    ./notify-send.nix
  ];

  home.packages = with pkgs; [
    mas
  ];

  targets.darwin = {
    search = "DuckDuckGo";
    defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        AppleKeyboardUIMode = 3;
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "Always";
      };
      dock = {
        autohide = true;
        orientation = "bottom";
        showhidden = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };
    };
  };
}
