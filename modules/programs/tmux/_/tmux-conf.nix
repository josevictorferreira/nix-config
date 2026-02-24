# tmux.conf content generator
# Takes plugins list and lib, returns the config string
{ lib }:
{ plugins }:
let
  applyPlugin = p: "run-shell ${if lib.types.package.check p then p.rtp else p.plugin.rtp}";
in
''
  unbind C-b
  set-option -g prefix C-a
  bind-key C-a send-prefix
  bind a send-prefix

  set -g base-index 1

  set -g mouse on

  set -g pane-base-index 1

  set -g default-terminal "tmux-256color"
  set -ag terminal-overrides ",tmux-256color:RGB"
  # Fix for ghost characters with Nerd Fonts and powerline symbols
  # Ensures proper width calculation across different terminals (ghostty, kitty, alacritty)
  set -ag terminal-overrides ",xterm-256color:RGB"
  set -g default-command "zsh"

  set -g history-limit 10000

  setw -g mode-keys vi
  set -g status-keys vi

  bind -T copy-mode-vi v send -X begin-selection
  bind P paste-buffer
  bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xsel -i -p && xsel -o -p | xsel -i -b"

  bind - split-window -v -c "#{pane_current_path}"
  bind = split-window -h -c "#{pane_current_path}"
  bind-key -r J resize-pane -D 5
  bind-key -r K resize-pane -U 5
  bind-key -r H resize-pane -L 5
  bind-key -r L resize-pane -R 5
  bind-key -r C-j resize-pane -D
  bind-key -r C-k resize-pane -U
  bind-key -r C-h resize-pane -L
  bind-key -r C-l resize-pane -R
  unbind '"'
  unbind %

  bind : command-prompt

  bind h select-pane -L
  bind j select-pane -D
  bind k select-pane -U
  bind l select-pane -R

  set -g status-justify left
  set -g status-interval 2

  set -g status-left '''

  set-option -g visual-activity off
  set-option -g visual-bell off
  set-option -g visual-silence off
  set-window-option -g monitor-activity off
  set-option -g bell-action none
  set-option -g focus-events on
  set-option -g escape-time 0

  bind x kill-pane
  bind X next-layout
  bind Z previous-layout

  bind -n S-down new-window
  bind -n S-left prev
  bind -n S-right next
  bind -n C-left swap-window -t -1
  bind -n C-right swap-window -t +1

  # tmuxp session picker (prefix + t, replaces default time display)
  bind t display-popup -E -w 60% -h 60% "tmuxp-picker"

  set -g status-position bottom
  set -g status-left '''
  set -g status-right-length 50
  set -g status-left-length 20

  setw -g aggressive-resize on
  setw -g allow-rename off
  set -g set-clipboard on
  setw -g @shell_mode 'vi'

  ${lib.strings.concatStringsSep "\n" (map applyPlugin plugins)}
''
