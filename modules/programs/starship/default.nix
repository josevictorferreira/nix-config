# Aspect: programs-starship
# Defines jvf.programs.starship options and platform-specific prompt config.
# NixOS: uses native programs.starship module.
# Darwin: manual install + TOML config + shell init hooks.
_:
let
  mkStarshipOptions = _: {
    options.jvf.programs.starship = { };
  };

  mkStarshipSettings =
    { colors }:
    let
      c = colors;
      green = "#${c.color2}";
      red = "#${c.color1}";
      blue = "#${c.color4}";
      black = "#${c.color0}";
      brightBlack = "#${c.color8}";
    in
    {
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
        style = "bold ${black}";
      };

      character = {
        success_symbol = "[➜](bold ${green})";
        error_symbol = "[✗](bold ${red})";
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "bold ${brightBlack}";
      };

      cmd_duration.disabled = false;

      git_branch = {
        symbol = "🌱 ";
      };

      status = {
        disabled = false;
        format = "[$symbol$status]($style) ";
        symbol = "✖  ";
      };

      nix_shell = {
        disabled = false;
        format = "via [☃️ $state( \\($name\\))](bold ${blue}) ";
        symbol = "❄️ ";
        impure_msg = "[impure shell](bold ${red})";
        pure_msg = "[pure shell](bold ${green})";
        style = "bold ${blue}";
      };
    };

  mkConfig =
    { isDarwin }:
    { lib
    , pkgs
    , config
    , ...
    }:
    let
      colors = config.jvf.theme.colors;
      starshipSettings = mkStarshipSettings { inherit colors; };
      tomlFormat = pkgs.formats.toml { };
      configFile = tomlFormat.generate "starship.toml" starshipSettings;
    in
    {
      imports = [ mkStarshipOptions ];

      config =
        if (!isDarwin) then
          {
            programs.starship = {
              enable = true;
              settings = starshipSettings;
            };

            # Deploy a writable starship.toml so the theme switcher can swap the
            # prompt colors per profile. NixOS's programs.starship only pins its
            # store config when ~/.config/starship.toml is absent (see the guard
            # it writes into /etc/zshrc), so this file takes precedence.
            jvf.home.users.${config.jvf.core.username}.items.".config/starship.toml" = {
              kind = "file";
              mode = "copy";
              source = configFile;
            };
          }
        else
          {
            environment.systemPackages = [ pkgs.starship ];

            # nix-darwin sets `programs.zsh.promptInit = "... prompt suse ..."` by default,
            # which runs AFTER interactiveShellInit and overrides starship. Clear it.
            programs.zsh.promptInit = lib.mkForce "";

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
          };
    };
in
{
  flake.modules.nixos.programs-starship = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-starship = mkConfig { isDarwin = true; };
}
