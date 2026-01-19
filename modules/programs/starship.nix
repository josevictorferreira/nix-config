{ config, lib, pkgs, options, system, ... }:

let
  cfg = config.jvf.programs.starship;
  isDarwin = builtins.match ".*-darwin" system != null;

  # Starship settings shared between NixOS and Darwin
  starshipSettings = {
    format = "$directory$git_branch$git_commit$git_state$git_status$nix_shell$character$kubernetes";
    add_newline = false;

    # Nix shell integration - Shows when inside nix develop/nix-shell
    nix_shell = {
      disabled = false;
      impure_msg = "";
      pure_msg = "[pure](bold green)";
      format = "via [$symbol$state( $name )]($style) ";
    };

    # Show full directory path (not just from git root)
    directory = {
      truncate_to_repo = false;
      fish_style_pwd_dir_length = 1;
    };

    # Kubernetes context at the end with icon
    kubernetes = {
      disabled = false;
      symbol = "☸️ ";
      format = "[$symbol$context( $namespace )]($style) ";
      style = "cyan bold";
      detect_files = [ ];
      detect_folders = [ ];
      detect_extensions = [ ];
    };

    # Additional customization to make it look nice
    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[➜](bold red)";
    };

    aws = {
      disabled = true;
    };
  };

  # Generate config file for Darwin (since programs.starship is missing in older nix-darwin)
  # Use pkgs.formats.toml for proper TOML generation
  format = pkgs.formats.toml { };
  configFile = format.generate "starship.toml" starshipSettings;

  # Check if the upstream option exists
  hasStarshipOption = options ? programs && options.programs ? starship;
in
{
  options.jvf.programs.starship = {
    enable = lib.mkEnableOption "Starship prompt";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # NixOS Configuration (using upstream module if available)
    # On Darwin, we prefer manual configuration to ensure reliability
    (lib.optionalAttrs (hasStarshipOption && !isDarwin) {
      programs.starship = {
        enable = true;
        settings = starshipSettings;
      };
    })

    # Darwin / Fallback Configuration (Manual implementation)
    # Applied if the upstream option is missing OR if we are explicitly on Darwin and want to force manual loading
    (lib.mkIf (!hasStarshipOption || isDarwin) {
      environment.systemPackages = [ pkgs.starship ];

      # environment.variables.STARSHIP_CONFIG = "${configFile}";

      programs.zsh.interactiveShellInit = lib.mkAfter ''
        # --- DEBUG: STARSHIP START ---
        export STARSHIP_CONFIG="${configFile}"
        # echo "DEBUG: Setting STARSHIP_CONFIG to $STARSHIP_CONFIG"
        
        if [[ -x "${pkgs.starship}/bin/starship" ]]; then
          eval "$(${pkgs.starship}/bin/starship init zsh)"
          # echo "DEBUG: Starship initialized"
        else
          echo "CRITICAL: Starship binary not found at ${pkgs.starship}/bin/starship"
        fi
        # --- DEBUG: STARSHIP END ---
      '';

      programs.bash.interactiveShellInit = lib.mkAfter ''
        export STARSHIP_CONFIG="${configFile}"
        eval "$(${pkgs.starship}/bin/starship init bash)"
      '';
    })
  ]);
}
