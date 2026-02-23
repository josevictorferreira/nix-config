# default.nix - ZSH shell module
{ lib, ... }:
let
  mkConfig =
    { isDarwin }:
    { config, pkgs, ... }:
    let
      cfg = config.jvf.programs.zsh;
    in
    {
      imports = [
        ./options.nix
        ./_/external-plugins.nix
        ./_/shell-init/environment.nix
        ./_/shell-init/history.nix
        ./_/shell-init/completion.nix
        ./_/shell-init/keybindings.nix
        ./_/aliases/base.nix
        ./_/aliases/navigation.nix
        ./_/aliases/ls.nix
        ./_/aliases/dev.nix
        ./_/aliases/k8s.nix
        ./_/aliases/notes.nix
        ./_/aliases/projects.nix
        ./_/aliases/work.nix
      ];

      config = {
        assertions = [
          {
            assertion = pkgs ? zsh;
            message = "zsh package must be available";
          }
        ];

        programs.zsh = lib.mkIf cfg.setAsDefaultShell {
          enable = true;
          oh-my-zsh = {
            enable = true;
            theme = "agnoster";
            plugins = cfg.plugins;
          };
        };

        # Set as default shell
        users.users.${cfg.username}.shell = lib.mkIf cfg.setAsDefaultShell (
          if isDarwin then pkgs.zsh else pkgs.zsh
        );
      };
    };
in
{
  flake.modules.nixos.programs-zsh = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-zsh = mkConfig { isDarwin = true; };
}
