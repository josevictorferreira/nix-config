{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.programs.zsh;

  options = import ./options.nix { inherit lib username; };
  aliases = import ./aliases.nix { inherit lib pkgs config; };
  environment = import ./environment.nix { inherit lib pkgs config; };
  history = import ./history.nix { inherit lib pkgs config; };
  keybindings = import ./keybindings.nix { inherit lib pkgs config; };
  zshPlugins = import ./plugins {
    inherit lib pkgs config;
  };

  completion = import ./completion.nix { inherit lib pkgs config; };
  tests = import ./tests.nix { inherit lib pkgs config; };
in
{
  imports = [
    options
    tests
  ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.zsh = {
          enable = true;

          interactiveShellInit = lib.concatStringsSep "\n" [
            # Enable Oh My Zsh (manual configuration to support both NixOS and Darwin)
            ''
              export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
              export ZSH_THEME=""
              plugins=(${lib.concatStringsSep " " zshPlugins.plugins})
              source $ZSH/oh-my-zsh.sh
            ''

            # Load custom themes
            (lib.concatStringsSep "\n" (
              map
                (pkg: ''
                  # Load ${pkg.name}
                  for script in ${pkg}/*.zsh-theme; do
                    if [ -f "$script" ]; then
                      source "$script"
                    fi
                  done
                '')
                zshPlugins.customThemes
            ))

            # Load custom plugins
            (lib.concatStringsSep "\n" (
              map
                (pkg: ''
                  # Load ${pkg.name}
                  for script in ${pkg}/*.plugin.zsh ${pkg}/*.zsh; do
                    if [ -f "$script" ]; then
                      source "$script"
                    fi
                  done
                '')
                zshPlugins.customPkgs
            ))

            # Force ls aliases after OMZ loading
            aliases.lsAliases
          ];

          shellInit = lib.concatStringsSep "\n" [
            environment.shellInit
            (lib.concatMapStringsSep "\n"
              (key: ''
                export ${lib.toUpper key}="$(cat /run/secrets/${key})"
              '')
              cfg.secrets.keys)
            history.shellInit
            completion.shellInit
            keybindings.shellInit
            aliases.shellInit
          ];

          loginShellInit = environment.loginInit;

          enableCompletion = true;
          enableBashCompletion = true;
          enableGlobalCompInit = true;
        };

        environment.shellAliases = aliases.structured;

        users.users.${cfg.username} = {
          shell = pkgs.zsh;
          packages = [
            pkgs.oh-my-zsh
            pkgs.fzf
            pkgs.ripgrep
            pkgs.eza
            pkgs.jq
            pkgs.curl
            pkgs.bat
          ];
        };

        sops.secrets = (
          lib.genAttrs cfg.secrets.keys (key: {
            owner = cfg.username;
            mode = "0400";
          })
        );
      }
      (lib.mkIf (cfg.setAsDefaultShell) {
        environment.shells = [
          pkgs.zsh
        ];
      })
    ]
  );
}
