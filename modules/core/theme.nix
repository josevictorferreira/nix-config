# Aspect: core-theme
# Global theme system -- defines jvf.theme options + built-in presets.
# Import = active. All desktop modules consume config.jvf.theme.*.
_:
let
  darkAmethyst = {
    colors = {
      background = "251E2D";
      foreground = "D3BDDB";
      cursor = "9570AC";
      color0 = "4C4354";
      color1 = "361356";
      color2 = "411B5D";
      color3 = "4B2264";
      color4 = "56296B";
      color5 = "613173";
      color6 = "613173";
      color7 = "B898C4";
      color8 = "806A89";
      color9 = "481A72";
      color10 = "56247C";
      color11 = "652D86";
      color12 = "73378F";
      color13 = "814199";
      color14 = "814199";
      color15 = "B898C4";
    };
    fonts = {
      monospace = "JetBrainsMono Nerd Font";
      sansSerif = "Fira Code";
      size = 14;
    };
    gtk = {
      theme = "Andromeda-dark";
      iconTheme = "Flat-Remix-Blue-Dark";
      cursorTheme = "Bibata-Modern-Ice";
      cursorSize = 24;
    };
    rofiSemantic = {
      activeBackground = "784CA0";
      activeForeground = "FAE8E1";
      normalBackground = "181519";
      normalForeground = "FAE8E1";
      urgentBackground = "CC659A";
      urgentForeground = "FAE8E1";
      selectedBackground = "CC659A";
      selectedForeground = "FAE8E1";
      borderColor = "784CA0";
    };
    backgroundAlpha = "0.25";
  };

  tokyonightNight = {
    colors = {
      background = "1a1b26";
      foreground = "c0caf5";
      cursor = "c0caf5";
      color0 = "15161e";
      color1 = "f7768e";
      color2 = "9ece6a";
      color3 = "e0af68";
      color4 = "7aa2f7";
      color5 = "bb9af7";
      color6 = "7dcfff";
      color7 = "a9b1d6";
      color8 = "414868";
      color9 = "f7768e";
      color10 = "9ece6a";
      color11 = "e0af68";
      color12 = "7aa2f7";
      color13 = "bb9af7";
      color14 = "7dcfff";
      color15 = "c0caf5";
    };
    fonts = {
      monospace = "JetBrainsMonoNL Nerd Font";
      sansSerif = "DejaVu Sans";
      size = 11;
    };
    gtk = {
      theme = "Andromeda-dark";
      iconTheme = "Flat-Remix-Blue-Dark";
      cursorTheme = "Bibata-Modern-Ice";
      cursorSize = 24;
    };
    rofiSemantic = {
      activeBackground = "7aa2f7";
      activeForeground = "1a1b26";
      normalBackground = "1a1b26";
      normalForeground = "c0caf5";
      urgentBackground = "f7768e";
      urgentForeground = "1a1b26";
      selectedBackground = "7aa2f7";
      selectedForeground = "1a1b26";
      borderColor = "7dcfff";
    };
    # Waybar background: near-solid (only consumer of backgroundAlpha).
    backgroundAlpha = "0.99";
  };

  tokyonightDay = {
    colors = {
      background = "e1e2e7";
      foreground = "3760bf";
      cursor = "3760bf";
      color0 = "e1e2e7";
      color1 = "f52a65";
      color2 = "587539";
      color3 = "8c6c3e";
      color4 = "2e7de9";
      color5 = "9854f1";
      color6 = "007197";
      color7 = "6172b0";
      color8 = "a8aecb";
      color9 = "f52a65";
      color10 = "587539";
      color11 = "8c6c3e";
      color12 = "2e7de9";
      color13 = "9854f1";
      color14 = "007197";
      color15 = "3760bf";
    };
    fonts = {
      monospace = "JetBrainsMonoNL Nerd Font";
      sansSerif = "DejaVu Sans";
      size = 11;
    };
    gtk = {
      theme = "Adwaita";
      iconTheme = "Adwaita";
      cursorTheme = "Bibata-Modern-Ice";
      cursorSize = 24;
      applicationPreferDarkTheme = false;
    };
    rofiSemantic = {
      activeBackground = "2e7de9";
      activeForeground = "e1e2e7";
      normalBackground = "e1e2e7";
      normalForeground = "3760bf";
      urgentBackground = "f52a65";
      urgentForeground = "e1e2e7";
      selectedBackground = "2e7de9";
      selectedForeground = "e1e2e7";
      borderColor = "a8aecb";
    };
    # Waybar background: near-solid (only consumer of backgroundAlpha).
    backgroundAlpha = "0.99";
  };

  contract = {
    hypr = "hypr";
    waybar = "waybar";
    rofi = "rofi";
    ags = "ags";
    terminals = "terminals";
    gtk = "gtk";
    kvantum = "kvantum";
    btop = "btop";
  };

  darkProfile = {
    preset = "tokyonight-night";
    displayName = "Dark";
    artifacts = contract;
  };

  lightProfile = {
    preset = "tokyonight-day";
    displayName = "Light";
    artifacts = contract;
  };
in
{
  flake.modules.nixos.core-theme =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.theme;
      username = config.jvf.core.username;

      mkProfileDir =
        profileName:
        let
          profileCfg = cfg.profiles.${profileName};
          registered = cfg.profileArtifacts.${profileName} or { };
        in
        pkgs.runCommand "jvf-theme-profile-${profileName}" { } ''
          mkdir $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              catName: subpath:
              let
                artifact = registered.${catName} or null;
              in
              if artifact != null then
                "ln -s ${lib.escapeShellArg "${artifact}"} $out/${lib.escapeShellArg subpath}"
              else
                "mkdir -p $out/${lib.escapeShellArg subpath}"
            ) profileCfg.artifacts
          )}
        '';
    in
    {
      imports = [ ./_/theme-options.nix ];

      config.jvf.theme.presets.dark-amethyst = darkAmethyst;
      config.jvf.theme.presets.tokyonight-night = tokyonightNight;
      config.jvf.theme.presets.tokyonight-day = tokyonightDay;

      config.jvf.theme.artifactContract = contract;
      config.jvf.theme.profiles.dark = darkProfile;
      config.jvf.theme.profiles.light = lightProfile;

      config.jvf.theme.paths = {
        artifactBase = ".local/share/jvf-theme/profiles";
        runtimeState = ".local/state/jvf-theme";
      };

      config.jvf.theme.profileSchedule.light = {
        start = "06:00";
        end = "12:00";
      };

      config.jvf.home.users.${username}.items = lib.mkMerge (
        lib.mapAttrsToList (profileName: _: {
          "${cfg.paths.artifactBase}/${profileName}" = {
            kind = "dir";
            mode = "copy";
            source = mkProfileDir profileName;
          };
        }) cfg.profiles
      );
    };

  flake.modules.darwin.core-theme = {
    imports = [ ./_/theme-options.nix ];

    config.jvf.theme.presets.dark-amethyst = darkAmethyst;
    config.jvf.theme.presets.tokyonight-night = tokyonightNight;
    config.jvf.theme.presets.tokyonight-day = tokyonightDay;

    config.jvf.theme.artifactContract = contract;
    config.jvf.theme.profiles.dark = darkProfile;
    config.jvf.theme.profiles.light = lightProfile;

    config.jvf.theme.paths = {
      artifactBase = ".local/share/jvf-theme/profiles";
      runtimeState = ".local/state/jvf-theme";
    };

    config.jvf.theme.profileSchedule.light = {
      start = "06:00";
      end = "12:00";
    };
  };
}
