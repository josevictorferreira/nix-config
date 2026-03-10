# aliases/navigation.nix - Navigation shortcuts for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Directory Navigation
    alias ws='cd ${cfg.workspace.root}'
    alias wspc='cd ${cfg.workspace.root}'
    alias hl='cd ${cfg.workspace.shared}'
    alias shared='cd ${cfg.workspace.shared}'
    alias dl='cd ~/Downloads'
    alias doc='cd ~/Documents'
    alias code='cd ~/Workspace'
    alias proj='cd ~/Workspace'
    alias dots='cd ~/.config'
    alias nixcfg='cd ~/.config/nix'
    alias nixc='cd ~/.config/nix'

    # Zoxide Integration
    alias z='__zoxide_z'
    alias zi='__zoxide_zi'
  '';
}
