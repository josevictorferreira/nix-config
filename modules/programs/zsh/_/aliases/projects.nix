# aliases/projects.nix - Project-specific aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Agrosmart
    "as" = "cd ${cfg.workspace.root}/agrosmart 2>/dev/null || cd ~/Workspace/agrosmart";

    # Valoris
    "val" = "cd ${cfg.workspace.root}/valoris 2>/dev/null || cd ~/Workspace/valoris";
    "valb" =
      "cd ${cfg.workspace.root}/valoris/valoris-backend 2>/dev/null || cd ~/Workspace/valoris/valoris-backend";
    "valf" =
      "cd ${cfg.workspace.root}/valoris/valoris-frontend 2>/dev/null || cd ~/Workspace/valoris/valoris-frontend";

    # Personal Projects
    "nixcfg" = "cd ~/.config/nix";
    "dotfiles" = "cd ~/.config";
  };
}
