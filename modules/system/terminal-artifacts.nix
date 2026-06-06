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
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      darkPreset = config.jvf.theme.presets.tokyonight-night;
      lightPreset = config.jvf.theme.presets.tokyonight-day;

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
