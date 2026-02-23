# aliases/ls.nix - LS aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    "ls" = "eza --icons --group-directories-first";
    "ll" = "eza -l --icons --group-directories-first";
    "la" = "eza -la --icons --group-directories-first";
    "lt" = "eza -T --icons --group-directories-first";
    "tree" = "eza -T --icons --group-directories-first";
  };
}
