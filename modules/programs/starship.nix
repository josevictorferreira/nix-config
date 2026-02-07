{ config
, lib
, pkgs
, options
, system
, ...
}:

let
  cfg = config.jvf.programs.starship;
  isDarwin = builtins.match ".*-darwin" system != null;

  # Starship settings
  starshipSettings = {
    # Disable AWS region display
    aws.disabled = true;

    # Shorter timeout to prevent lag in large directories
    command_timeout = 500; # milliseconds

    # Increase directory scan timeout to prevent warnings in large dirs (like ~)
    scan_timeout = 1000; # milliseconds

    # Show full directory path instead of truncated
    directory = {
      truncation_length = 0;
      truncate_to_repo = false;
    };

    # Enable line break to put cursor on next line after status
    # This separates the status line (dir, git) from the input line
    line_break.disabled = false;

    # Add newline between prompts for cleaner separation
    add_newline = true;

    # Transient prompt - clears old prompts when typing new commands
    # This helps prevent ghost characters by redrawing clean
    continuation_prompt = "▶ ";

    # Disable right-aligned modules that can cause width calculation issues
    # These can interfere with proper line clearing
    battery.disabled = true;

    # Custom format: directory/git on left, time on right (via fill), cursor on next line
    format = "$directory$git_branch$git_status$fill$time\n$character";

    # CRITICAL: Add fill module to prevent ghost characters
    # This ensures proper spacing calculation when modules appear/disappear
    fill = {
      disabled = false;
      symbol = " ";
      style = "bold black";
    };

    # Character config with explicit symbols for proper width calculation
    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[✗](bold red)";
    };

    # Configure time module with proper formatting (right-aligned via fill)
    time = {
      disabled = false;
      format = "[$time]($style)";
      style = "bold bright-black";
    };

    # Disable cmd_duration to reduce dynamic content changes
    cmd_duration.disabled = true;

    # Ensure proper git branch display without extra spaces
    git_branch = {
      format = "[$branch]($style)";
    };

    # Status module config to avoid width issues
    status = {
      disabled = false;
      format = "[$symbol$status]($style) ";
      symbol = "✖";
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
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
          export STARSHIP_TRANSIENT_PROMPT=true
          # echo "DEBUG: Setting STARSHIP_CONFIG to $STARSHIP_CONFIG"

          if [[ -x "${pkgs.starship}/bin/starship" ]]; then
            eval "$(${pkgs.starship}/bin/starship init zsh)"
            # Enable transient prompt to prevent ghost characters
            # This clears the previous prompt when a new command is entered
            enable_transient_prompt
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
    ]
  );
}
