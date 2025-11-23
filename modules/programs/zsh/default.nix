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
  functions = import ./functions { inherit lib pkgs config; };
  history = import ./history.nix { inherit lib pkgs config; };
  keybindings = import ./keybindings.nix { inherit lib pkgs config; };
  plugins = import ./plugins.nix {
    inherit lib pkgs;
    viMode = cfg.features.viMode;
  };
  prompt = import ./prompt.nix { inherit lib pkgs config; };
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
        (lib.optionalString cfg.features.powerLevel10k prompt.shellInit)
        (lib.concatMapStringsSep "\n" (key: ''
          export ${lib.toUpper key}="$(cat /run/secrets/${key})"
        '') cfg.secrets.keys)
      ];

      # Interactive shell configuration
      interactiveShellInit = lib.concatStringsSep "\n\n" [
        # Plugin configuration (manual sourcing)
        (lib.concatMapStringsSep "\n" (plugin: ''
          # Load ${plugin.name}
          if [[ -f ${plugin.src}/${plugin.name}.plugin.zsh ]]; then
            source ${plugin.src}/${plugin.name}.plugin.zsh
          elif [[ -f ${plugin.src}/${plugin.name}.zsh ]]; then
            source ${plugin.src}/${plugin.name}.zsh
          else
            # Fallback to finding any .plugin.zsh file
            for f in ${plugin.src}/*.plugin.zsh(N); do
              source "$f"
              break
            done
          fi
        '') plugins.list)

        history.config
        completion.config
        keybindings.config
        functions.all
        aliases.config
      ];

      # Login shell configuration
      loginShellInit = environment.loginInit;

      # Shell aliases (structured)
      shellAliases = aliases.structured;
    };

    # System-level configuration
    environment = {
      shells = [ pkgs.zsh ];
      variables.ZDOTDIR = "$HOME/.config/zsh";
      systemPackages = with pkgs; [
        zsh
        fzf
        ripgrep
        direnv
        eza
        jq
        curl
      ];
    };

    # User configuration
    users.users.${cfg.username} = lib.mkIf cfg.setAsDefaultShell {
      shell = pkgs.zsh;
    };

    sops.secrets = (
      lib.genAttrs cfg.secrets.keys (key: {
        owner = cfg.username;
        mode = "0400";
      })
    );
  };
}
