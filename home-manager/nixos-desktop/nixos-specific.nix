{ pkgs, username, ... }:

let
  inherit (import ./variables.nix) gitUsername;
in
{
  imports = [
    ../shared/default.nix
    ../shared/ghostty.nix
    ./hyprland.nix
  ];

  users = {
    users."${username}" = {
      homeMode = "755";
      isNormalUser = true;
      description = "${gitUsername}";
      extraGroups = [
        "networkmanager"
        "wheel"
        "libvirtd"
        "scanner"
        "lp"
        "video"
        "input"
        "audio"
      ];
      packages = [ ]; # Packages handled by Home Manager
    };

    defaultUserShell = pkgs.zsh;
  };

  programs.zsh = {
    enable = true;
    promptInit = "";
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  system.activationScripts = { };
}
