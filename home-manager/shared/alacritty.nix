{ pkgs, lib, config, configRoot, ... }:

with lib;
let
  cfg = config.modules.alacritty;
in
{
  options.modules.alacritty = {
    enable = mkEnableOption "alacritty";
  };
  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
    };
    home = {
      packages = [
        pkgs.alacritty
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.noto-fonts
        pkgs.noto-fonts-emoji
        pkgs.maple-mono.truetype
        pkgs.commit-mono
      ];
      file = {
        ".config/alacritty/" = {
          source = "${configRoot}/dotfiles/alacritty/";
        };
      };
    };
  };
}
