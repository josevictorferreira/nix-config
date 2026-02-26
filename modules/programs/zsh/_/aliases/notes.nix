# aliases/notes.nix - Notes management aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Notes
    "notes" = "cd ~/Notes && nvim";
    "nt" = "cd ~/Notes && nvim";
    "nsearch" = "rg ~/Notes";
    # Todo (homelab shared)
    "gtodo" = "nvim ~/Homelab/notetaking/checklists/Todo.md";
  };
}
