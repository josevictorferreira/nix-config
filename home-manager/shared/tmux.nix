{ pkgs, configRoot, ... }:

let
  tmuxConfigDir = "${configRoot}/config/tmux";
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
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
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'
          set -g @continuum-save-interval 'on'
        '';
      }
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
