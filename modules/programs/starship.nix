{ config, lib, ... }:

let
  cfg = config.jvf.programs.starship;
in
{
  options.jvf.programs.starship = {
    enable = lib.mkEnableOption "Starship prompt";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = {
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
      };
    };
  };
}
