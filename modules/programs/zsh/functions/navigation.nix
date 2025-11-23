{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;
  notesDir = "${cfg.workspace.shared}/notetaking";
in
{
  functions = ''
    # Interactive alias selection and execution
    function als() {
      local cmd=$(alias | sed "s/^alias //" | \
        ${pkgs.fzf}/bin/fzf --ansi --height 20 \
          --preview "echo {}" | \
        awk -F'=' '{print $2}' | tr -d "'")
      if [[ -n $cmd ]]; then
        eval "$cmd"
      fi
    }

    # Interactive note browser with fzf
    function notes() {
      local NOTES_DIR="${notesDir}"
      emulate -L zsh -o pipefail

      if [[ -z "$NOTES_DIR" || ! -d "$NOTES_DIR" ]]; then
        print -u2 "NOTES_DIR not accessible: ''${NOTES_DIR:-<unset>}"
        return 1
      fi

      command -v ${pkgs.fzf}/bin/fzf  >/dev/null || { print -u2 "fzf required"; return 1; }
      command -v ${pkgs.neovim}/bin/nvim >/dev/null || { print -u2 "neovim required"; return 1; }

      local -a LIST_CMD
      if command -v ${pkgs.fd}/bin/fd >/dev/null; then
        LIST_CMD=(${pkgs.fd}/bin/fd --hidden --follow --absolute-path -t f -e md . "$NOTES_DIR")
      elif command -v ${pkgs.ripgrep}/bin/rg >/dev/null; then
        LIST_CMD=(${pkgs.ripgrep}/bin/rg --hidden -uu -g '**/*.md' -l --no-messages "$NOTES_DIR")
      else
        LIST_CMD=(${pkgs.findutils}/bin/find "$NOTES_DIR" -type f -name '*.md' -print)
      fi

      local PREVIEW_CMD
      if command -v ${pkgs.glow}/bin/glow >/dev/null; then
        PREVIEW_CMD='${pkgs.glow}/bin/glow --style dark --width 120 {}'
      elif command -v ${pkgs.bat}/bin/bat >/dev/null; then
        PREVIEW_CMD='${pkgs.bat}/bin/bat --style=numbers --color=always --line-range=:500 {}'
      else
        PREVIEW_CMD='sed -n "1,200p" -- {}'
      fi

      local -a picks
      picks=("''${(@f)$(
        "''${LIST_CMD[@]}" \
          | sort -f \
          | ${pkgs.fzf}/bin/fzf --multi \
                --height=80% \
                --reverse \
                --prompt='notes> ' \
                --preview="$PREVIEW_CMD" \
                --preview-window=right,60%,border \
                --bind='ctrl-a:toggle-all'
      )}")

      (( ''${#picks} )) || return 0

      ${pkgs.neovim}/bin/nvim -- "''${picks[@]}"
    }
  '';
}
