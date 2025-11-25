{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.programs.zsh;

  options = import ./options.nix { inherit lib username; };
  aliases = import ./aliases.nix { inherit lib pkgs config; };
  environment = import ./environment.nix { inherit lib pkgs config; };
  history = import ./history.nix { inherit lib pkgs config; };
  keybindings = import ./keybindings.nix { inherit lib pkgs config; };
  plugins = import ./plugins {
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

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;

      # Merge all shell initialization
      shellInit = lib.concatStringsSep "\n" [
        environment.shellInit

        # Load secrets env variables
        (lib.concatMapStringsSep "\n" (key: ''
          export ${lib.toUpper key}="$(cat /run/secrets/${key})"
        '') cfg.secrets.keys)

        history.shellInit
        completion.shellInit
        keybindings.shellInit
        plugins.shellInit
        aliases.shellInit
      ];

      ohMyZsh = {
        enable = true;
        theme = cfg.theme;
      }
      // plugins;

      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
          "cursor"
          "regexp"
          "line"
          "root"
          "pattern"
        ];
      };

      loginShellInit = environment.loginInit;

      enableLsColors = true;
      enableCompletion = true;
      enableBashCompletion = true;

      autosuggestions = {
        enable = true;
        async = true;
      };

      vteIntegration = true;

      shellAliases = aliases.structured;
    };

    users.users.${cfg.username} = lib.mkIf cfg.setAsDefaultShell {
      shell = pkgs.zsh;
      packages = [
        pkgs.fzf
        pkgs.ripgrep
        pkgs.direnv
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
  };
}
