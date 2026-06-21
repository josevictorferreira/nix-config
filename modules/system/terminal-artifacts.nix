# Aspect: system-terminal-artifacts
# Aggregates terminal/CLI profile artifacts for dual-theme runtime switching.
# Imports pure generators from each terminal module and builds combined
# dark/light derivations registered under jvf.theme.profileArtifacts.*.terminals.
_:
let
  # Import pure config generators
  mkKittyConf = import ./../programs/kitty/_/kitty-conf.nix;
  mkAlacrittyConf = import ./../programs/alacritty/_/alacritty-conf.nix;
  mkStarshipConf = import ./../programs/starship/_/starship-conf.nix;
  mkTmuxConf = import ./../programs/tmux/_/tmux-conf.nix;
  k9sSkinFn = import ./../programs/k9s/_/skin.nix;

  terminalArtifactModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Heavier terminal body text (both themes) — Regular strokes look thin,
      # especially on the light background. Bold text still uses the Bold face.
      terminalFont = "JetBrainsMonoNL NF SemiBold";
      darkPreset = lib.recursiveUpdate config.jvf.theme.presets.tokyonight-night {
        fonts.monospace = terminalFont;
      };
      # Terminal-only contrast tweaks for the light theme: the default
      # tokyonight-day foreground (#3760bf) and blue (#2e7de9) are hard to read
      # on the #e1e2e7 background. Darken them here so kitty/alacritty/tmux are
      # legible, while waybar/rofi/gtk keep the unmodified tokyonight-day palette.
      lightPreset = lib.recursiveUpdate config.jvf.theme.presets.tokyonight-day {
        colors = {
          foreground = "343b58";
          # Blue / bright-blue: #284b8f (~4.85:1) still read as too light on the
          # #e1e2e7 background. Deepen to ~8.5:1 (AAA) while staying blue.
          color4 = "1c3a6e";
          color12 = "1c3a6e";
          # "bright black"/dim slot: default #a8aecb is a pale lavender-blue at
          # ~1.7:1 — unreadable for dim text (shell hints, comments). Use Tokyo
          # Night's comment slate for ~4.8:1 while staying muted.
          color8 = "565f89";
          # "white"/"bright white" slots default to light blues (#6172b0/#3760bf)
          # in tokyonight-day — but these are the slots used for normal/bold
          # default text, so washed-out light-blue text shows up everywhere on
          # the light background. Darken while keeping the blue identity.
          color7 = "3f4a6b";
          # bright-white slot: #34548a (~5.8:1) also read as too light; deepen.
          color15 = "243b66";
        };
        # SemiBold body text (shared with dark via terminalFont). Fontconfig
        # alias resolves for kitty and alacritty.
        fonts.monospace = terminalFont;
      };

      tomlFmt = pkgs.formats.toml { };
      yamlFmt = pkgs.formats.yaml { };

      mkTerminalArtifact =
        name: preset:
        let
          kittyConf = mkKittyConf { inherit lib; } { inherit preset; };
          alacrittyConf = mkAlacrittyConf { inherit lib; } { inherit preset; };
          starshipConf = mkStarshipConf { inherit lib; } { inherit preset; };
          tmuxConf = mkTmuxConf { inherit lib; } {
            plugins = config.jvf.programs.tmux.plugins;
            colors = preset.colors;
          };
          k9sSkin = k9sSkinFn preset.colors;
        in
        pkgs.runCommand "theme-terminals-${name}" { } ''
          mkdir -p $out

          # Kitty
          cat > $out/kitty.conf << 'KITTY_EOF'
          ${kittyConf}
          KITTY_EOF

          # Alacritty
          cp ${tomlFmt.generate "alacritty-${name}.toml" alacrittyConf} $out/alacritty.toml

          # Starship
          cp ${tomlFmt.generate "starship-${name}.toml" starshipConf} $out/starship.toml

          # Tmux
          cat > $out/tmux.conf << 'TMUX_EOF'
          ${tmuxConf}
          TMUX_EOF

          # K9s skin
          mkdir -p $out/k9s
          cp ${yamlFmt.generate "k9s-skin-${name}.yaml" { k9s = k9sSkin; }} $out/k9s/tokyonight.yaml
        '';
    in
    {
      imports = [ ./../programs/tmux/options.nix ];

      config.jvf.theme.profileArtifacts = {
        dark.terminals = mkTerminalArtifact "dark" darkPreset;
        light.terminals = mkTerminalArtifact "light" lightPreset;
      };
    };
in
{
  flake.modules.nixos.system-terminal-artifacts = terminalArtifactModule;
  flake.modules.darwin.system-terminal-artifacts = terminalArtifactModule;
}
