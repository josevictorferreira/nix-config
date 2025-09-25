{ pkgs, configRoot, ... }:

let
  tmuxConfigDir = "${configRoot}/dotfiles/tmux";
in
{
  home.sessionVariables = {
    TMUXP_CONFIGDIR = "$HOME/.config/tmux/tmuxp";
  };

  home.file.".config/tmux/tmuxp/" = {
    source = "${tmuxConfigDir}/tmuxp";
    recursive = true;
    executable = false;
  };

  home.file.".config/tmux/scripts/" = {
    source = "${tmuxConfigDir}/scripts";
    recursive = true;
    executable = false;
  };

  home.packages = with pkgs; [
    tmux
    tmuxp
  ];

  programs.tmux = {
    enable = true;
    newSession = true;
    baseIndex = 1;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;
    clock24 = false;
    focusEvents = true;
    historyLimit = 10000;
    escapeTime = 0;
    aggressiveResize = true;
    extraConfig = builtins.readFile "${tmuxConfigDir}/tmux.conf";
    plugins = with pkgs.tmuxPlugins; [
      yank
      sensible
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          set -g @tokyo-night-tmux_theme storm    # storm | day | default to 'night'
          set -g @tokyo-night-tmux_transparent 1  # 1 or 0
          set -g @tokyo-night-tmux_window_id_style digital
          set -g @tokyo-night-tmux_pane_id_style hsquare
          set -g @tokyo-night-tmux_zoom_id_style dsquare
        '';
      }
    ];
  };
}
