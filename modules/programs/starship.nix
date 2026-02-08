{
  config,
  lib,
  pkgs,
  options,
  system,
  ...
}:

let
  cfg = config.jvf.programs.starship;
  isDarwin = builtins.match ".*-darwin" system != null;

  starshipSettings = {
    aws.disabled = true;

    directory = {
      truncation_length = 0;
      truncate_to_repo = false;
    };

    add_newline = true;

    battery.disabled = true;

    format = "$directory$git_branch$git_status$nix_shell$fill$time$line_break$character";

    fill = {
      disabled = false;
      symbol = " ";
      style = "bold black";
    };

    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[✗](bold red)";
    };

    time = {
      disabled = false;
      format = "[$time]($style)";
      style = "bold bright-black";
    };

    cmd_duration.disabled = false;

    git_branch = {
      symbol = "🌱 ";
      truncation_length = 4;
      truncation_symbol = "";
    };

    status = {
      disabled = false;
      format = "[$symbol$status]($style) ";
      symbol = "✖  ";
    };

    nix_shell = {
      disabled = false;
      format = "via [☃️ $state( \($name\))](bold blue) ";
      symbol = "❄️ ";
      impure_msg = "[impure shell](bold red)";
      pure_msg = "[pure shell](bold green)";
      style = "bold blue";
    };
  };

  format = pkgs.formats.toml { };
  configFile = format.generate "starship.toml" starshipSettings;

  hasStarshipOption = options ? programs && options.programs ? starship;
in
{
  options.jvf.programs.starship = {
    enable = lib.mkEnableOption "Starship prompt";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.optionalAttrs (hasStarshipOption && !isDarwin) {
        programs.starship = {
          enable = true;
          settings = starshipSettings;
        };
      })

      (lib.mkIf (!hasStarshipOption || isDarwin) {
        environment.systemPackages = [ pkgs.starship ];

        programs.zsh.interactiveShellInit = lib.mkAfter ''
          export STARSHIP_CONFIG="${configFile}"

          if [[ -x "${pkgs.starship}/bin/starship" ]]; then
            eval "$(${pkgs.starship}/bin/starship init zsh)"
          else
            echo "CRITICAL: Starship binary not found at ${pkgs.starship}/bin/starship"
          fi
        '';

        programs.bash.interactiveShellInit = lib.mkAfter ''
          export STARSHIP_CONFIG="${configFile}"
          eval "$(${pkgs.starship}/bin/starship init bash)"
        '';
      })
    ]
  );
}
