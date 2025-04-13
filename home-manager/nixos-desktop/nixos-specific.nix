{ host, configRoot, ... }:

let
  inherit (import "${configRoot}/hosts/${host}/variables.nix") gitUsername;
in
{
  imports = [
    ../shared/default.nix
    ../shared/ghostty.nix
    ./hyprland.nix
  ];

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
