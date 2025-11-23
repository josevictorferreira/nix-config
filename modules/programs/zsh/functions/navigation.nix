{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;
  notesDir = "${cfg.workspace.shared}/notetaking";

  # Notes script wrapper
  notes = pkgs.writeShellApplication {
    name = "notes";
    runtimeInputs = [
      pkgs.fzf
      pkgs.neovim
      pkgs.fd
      pkgs.ripgrep
      pkgs.findutils
      pkgs.glow
      pkgs.bat
    ];
    text = ''
      # Interactive note browser with fzf
      # Expects NOTES_DIR env var to be set
      export NOTES_DIR="${notesDir}"

      if [[ -z "$NOTES_DIR" || ! -d "$NOTES_DIR" ]]; then
        echo "NOTES_DIR not accessible: ''${NOTES_DIR:-<unset>}" >&2
        exit 1
      fi

      # Verify dependencies
      for cmd in fzf nvim; do
        if ! command -v "$cmd" >/dev/null; then
          echo "$cmd required" >&2
          exit 1
        fi
      done

      # Select list command based on availability
      if command -v fd >/dev/null; then
        mapfile -t LIST_CMD < <(fd --hidden --follow --absolute-path -t f -e md . "$NOTES_DIR")
      elif command -v rg >/dev/null; then
        mapfile -t LIST_CMD < <(rg --hidden -uu -g '**/*.md' -l --no-messages "$NOTES_DIR")
      else
        mapfile -t LIST_CMD < <(find "$NOTES_DIR" -type f -name '*.md' -print)
      fi

      # Select preview command
      if command -v glow >/dev/null; then
        PREVIEW_CMD='glow --style dark --width 120 {}'
      elif command -v bat >/dev/null; then
        PREVIEW_CMD='bat --style=numbers --color=always --line-range=:500 {}'
      else
        PREVIEW_CMD='sed -n "1,200p" -- {}'
      fi

      # Run FZF
      # Note: bash arrays are "''${arr[@]}".
      # We pipe the file list to fzf
      printf "%s\n" "''${LIST_CMD[@]}" | sort -f | fzf --multi \
        --height=80% \
        --reverse \
        --prompt='notes> ' \
        --preview="$PREVIEW_CMD" \
        --preview-window=right,60%,border \
        --bind='ctrl-a:toggle-all' | \
      xargs -r -d '\n' nvim
    '';
  };
in
{
  packages = [ notes ];
  shellInit = ''
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
  '';
}
