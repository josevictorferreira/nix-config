# tmux.conf content generator
# Takes plugins list, colors, and lib, returns the config string
{ lib }:
{ plugins, colors }:
let
  applyPlugin = p: "run-shell ${if lib.types.package.check p then p.rtp else p.plugin.rtp}";

  # Powerline separator characters (actual Unicode, not escape sequences)
  sep_full = "";
  sep_thin = "";
  sep_left_full = "";
  sep_left_thin = "";

  # Color aliases for readability — tokyonight-night purple/dark theme
  bg = colors.background;
  fg = colors.foreground;
  accent = colors.color5;        # bb9af7 — purple
  accent_fg = colors.background; # 1a1b26 — dark background
  dim = colors.color8;           # 414868 — muted gray
  muted = colors.color0;         # 15161e — darker shade

  # Powerline-style status segments
  statusLeft = ''
    set -g status-left "#[bg=#${accent},fg=#${accent_fg},bold] #S #[bg=#${bg},fg=#${accent}]${sep_full}"
    set -g status-left-length 40
  '';

  statusRight = ''
    set -g status-right "#[bg=#${bg},fg=#${dim}]${sep_left_full}#[bg=#${dim},fg=#${fg}] #h ${sep_left_full}#[bg=#${accent},fg=#${accent_fg}] %Y-%m-%d %H:%M "
    set -g status-right-length 60
  '';

  windowStatus = ''
    set -g window-status-format "#[bg=#${dim},fg=#${bg}]${sep_full}#[bg=#${dim},fg=#${fg}] #I ${sep_thin} #W #[bg=#${bg},fg=#${dim}]${sep_full}"
    set -g window-status-current-format "#[bg=#${accent},fg=#${bg}]${sep_full}#[bg=#${accent},fg=#${accent_fg},bold] #I ${sep_thin} #W #[bg=#${bg},fg=#${accent}]${sep_full}"
    set -g window-status-separator ""
  '';

  # Generate style directives from theme colors
  # Hex colors in tmux need # prefix; our palette stores them without #
  styleDirectives = ''
    # === Theme colors (generated from jvf.theme.colors) ===
    set -g status-style "bg=#${colors.background},fg=#${colors.foreground}"
    set -g status-left-style "bg=#${colors.color5},fg=#${colors.background},bold"
    set -g status-right-style "bg=#${colors.color8},fg=#${colors.foreground}"
    set -g window-status-style "bg=#${colors.background},fg=#${colors.color8}"
    set -g window-status-current-style "bg=#${colors.color5},fg=#${colors.background},bold"
    set -g pane-border-style "fg=#${colors.color8}"
    set -g pane-active-border-style "fg=#${colors.color5}"
    set -g message-style "bg=#${colors.background},fg=#${colors.color3}"
    set -g mode-style "bg=#${colors.color5},fg=#${colors.background}"
  '';
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
  set -g status-right-length 60
  set -g status-left-length 40

  setw -g aggressive-resize on
  setw -g allow-rename off
  set -g set-clipboard on
  setw -g @shell_mode 'vi'

  ${statusLeft}
  ${statusRight}
  ${windowStatus}

  ${styleDirectives}
  ${lib.strings.concatStringsSep "\n" (map applyPlugin plugins)}
''
