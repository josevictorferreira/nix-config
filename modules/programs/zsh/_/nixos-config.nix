# _/nixos-config.nix - NixOS-specific ZSH configuration
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  config = lib.mkIf cfg.setAsDefaultShell {
    programs.zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        theme = "agnoster";
        inherit (cfg) plugins;
      };
    };
  };
}
