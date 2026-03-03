# Aspect: core-theme
# Global theme system — defines jvf.theme options + built-in presets.
# Import = active. All desktop modules consume config.jvf.theme.*.
_: {
  flake.modules.nixos.core-theme = {
    imports = [
      ./_/theme-options.nix
    ];

    config.jvf.theme.presets.dark-amethyst = {
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

    config.jvf.theme.presets.tokyonight-night = {
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
        selectedBackground = "bb9af7";
        selectedForeground = "1a1b26";
        borderColor = "7aa2f7";
      };
      backgroundAlpha = "0.25";
    };
  };

  flake.modules.darwin.core-theme = {
    imports = [
      ./_/theme-options.nix
    ];

    config.jvf.theme.presets.dark-amethyst = {
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

    config.jvf.theme.presets.tokyonight-night = {
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
        selectedBackground = "bb9af7";
        selectedForeground = "1a1b26";
        borderColor = "7aa2f7";
      };
      backgroundAlpha = "0.25";
    };
  };
}
