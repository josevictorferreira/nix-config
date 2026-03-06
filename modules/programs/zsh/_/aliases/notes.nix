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
    "gtodo" = "nvim ~/Homelab/notetaking/01-projects/active/Todo.md";
    # Encrypted plan file (sops)
    "plan" =
      "sops --config=${cfg.workspace.shared}/.sops.yaml ${cfg.workspace.shared}/notetaking/00-inbox/plan.enc.md";
  };
}
