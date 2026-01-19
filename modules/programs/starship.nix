{ config, lib, pkgs, options, system, ... }:

let
  cfg = config.jvf.programs.starship;
  isDarwin = builtins.match ".*-darwin" system != null;

  # Starship settings - use defaults to fix display issues
  starshipSettings = { };

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
