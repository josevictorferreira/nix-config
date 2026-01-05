{ config, lib, pkgs, options, system, ... }:

let
  cfg = config.jvf.programs.starship;
  isDarwin = builtins.match ".*-darwin" system != null;

  # Starship settings shared between NixOS and Darwin
  starshipSettings = {
    add_newline = true;

    # Nix shell integration - Shows when inside nix develop/nix-shell
    nix_shell = {
      disabled = false;
      impure_msg = "[impure](bold red)";
      pure_msg = "[pure](bold green)";
      format = "via [$symbol$state( \($name\))]($style) ";
    };

    # Additional customization to make it look nice
    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[➜](bold red)";
    };

    aws = {
      disabled = true;
    };

    kubernetes = {
      disabled = false;
    };
  };

  # Generate config file for Darwin (since programs.starship is missing in older nix-darwin)
  # Uses builtins.toJSON as a poor man's TOML generator since it is mostly compatible for simple keys
  # or uses the custom library if available via inputs (would need access to inputs)
  # But simpler: just define a helper here or use pkgs.formats if available.
  # Given the error 'attribute toTOML missing', standard lib doesn't have it here.
  # We'll use a local helper to convert to TOML-compatible format.
  toTOML = attrs:
    let
      toTOMLValue = v:
        if builtins.isBool v then (if v then "true" else "false")
        else if builtins.isInt v then builtins.toString v
        else if builtins.isString v then "\"${v}\""
        else if builtins.isAttrs v then "" # Handled by section headers or key-value pairs
        else "\"${builtins.toString v}\"";

      # Simple flattener for 1-level tables (sections) and top-level keys
      process = attrs: concatStringsSep "\n" (
        mapAttrsToList
          (k: v:
            if builtins.isAttrs v then
              "\n[${k}]\n" + (concatStringsSep "\n" (mapAttrsToList (sk: sv: "${sk} = ${toTOMLValue sv}") v))
            else
              "${k} = ${toTOMLValue v}"
          )
          attrs
      );

      inherit (lib) concatStringsSep mapAttrsToList;
    in
    process attrs;

  configFile = pkgs.writeText "starship.toml" (toTOML starshipSettings);

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
