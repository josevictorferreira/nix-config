# aliases/projects.nix - Project-specific aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Agrosmart
    alias as='cd ${cfg.workspace.root}/agrosmart 2>/dev/null || cd ~/Workspace/agrosmart'

    # Valoris
    alias val='cd ${cfg.workspace.root}/valoris 2>/dev/null || cd ~/Workspace/valoris'
    alias valb='cd ${cfg.workspace.root}/valoris/backend 2>/dev/null || cd ~/Workspace/valoris/backend'
    alias valf='cd ${cfg.workspace.root}/valoris/valoris-frontend 2>/dev/null || cd ~/Workspace/valoris/valoris-frontend'

    # Personal Projects
    alias nixcfg='cd ~/.config/nix'
    alias dotfiles='cd ~/.config'

    # Legacy workspace projects
    alias exer='cd ${cfg.workspace.root}/exercism'
    alias readm='cd ${cfg.workspace.root}/readmore-project'
    alias ebook='cd ${cfg.workspace.root}/ebookit'
    alias ebookit='cd ${cfg.workspace.root}/ebookit/ebookit-extension'
    alias rinha='cd ${cfg.workspace.root}/rinha-backend'
  '';
}
