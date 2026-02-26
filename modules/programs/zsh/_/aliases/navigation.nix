# aliases/navigation.nix - Navigation shortcuts for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Directory Navigation
    "ws" = "cd ${cfg.workspace.root}";
    "wspc" = "cd ${cfg.workspace.root}";
    "hl" = "cd ${cfg.workspace.shared}";
    "shared" = "cd ${cfg.workspace.shared}";
    "dl" = "cd ~/Downloads";
    "doc" = "cd ~/Documents";
    "code" = "cd ~/Workspace";
    "proj" = "cd ~/Workspace";
    "dots" = "cd ~/.config";
    "nixcfg" = "cd ~/.config/nix";
    "nixc" = "cd ~/.config/nix";

    # Zoxide Integration
    "z" = "__zoxide_z";
    "zi" = "__zoxide_zi";
  };
}
