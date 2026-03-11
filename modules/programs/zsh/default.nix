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
        # Cross-platform: all supported by both NixOS and nix-darwin
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
        ./_/functions/git-ai.nix
        ./_/functions/development.nix
        ./_/functions/kubernetes.nix
        ./_/functions/navigation.nix
      ]
      ++ lib.optionals isDarwin [ ./_/shell-init/oh-my-zsh-darwin.nix ];

      config = lib.mkIf cfg.setAsDefaultShell {
        assertions = [
          {
            assertion = pkgs ? zsh;
            message = "zsh package must be available";
          }
        ];

        programs.zsh = {
          enable = true;
        }
        // lib.optionalAttrs (!isDarwin) {
          # nix-darwin doesn't have ohMyZsh option, handled separately for Darwin
          ohMyZsh = {
            enable = true;
            inherit (cfg) theme plugins;
          };
        };

        # On Darwin we need to add oh-my-zsh to systemPackages manually
        environment.systemPackages = lib.mkIf isDarwin [ pkgs.oh-my-zsh ];

        # Set as default shell
        users.users.${cfg.username}.shell = pkgs.zsh;
      };
    };
in
{
  flake.modules.nixos.programs-zsh = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-zsh = mkConfig { isDarwin = true; };
}
