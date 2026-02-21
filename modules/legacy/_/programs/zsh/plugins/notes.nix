{ pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;
  notesDir = "${cfg.workspace.shared}/notetaking";
in
pkgs.stdenv.mkDerivation {
  name = "zsh-notes";
  src = pkgs.writeTextDir "zsh-notes.plugin.zsh" ''
    function notes() {
      export NOTES_DIR="${notesDir}"

      if [[ -z "$NOTES_DIR" || ! -d "$NOTES_DIR" ]]; then
        echo "NOTES_DIR not accessible: ''${NOTES_DIR:-<unset>}" >&2
        return 1
      fi

      # Select list command based on availability
      local LIST_CMD
      if command -v ${pkgs.fd}/bin/fd >/dev/null; then
        mapfile -t LIST_CMD < <(${pkgs.fd}/bin/fd --hidden --follow --absolute-path -t f -e md . "$NOTES_DIR")
      elif command -v ${pkgs.ripgrep}/bin/rg >/dev/null; then
        mapfile -t LIST_CMD < <(${pkgs.ripgrep}/bin/rg --hidden -uu -g '**/*.md' -l --no-messages "$NOTES_DIR")
      else
        mapfile -t LIST_CMD < <(${pkgs.findutils}/bin/find "$NOTES_DIR" -type f -name '*.md' -print)
      fi

      # Select preview command
      local PREVIEW_CMD
      if command -v ${pkgs.glow}/bin/glow >/dev/null; then
        PREVIEW_CMD='${pkgs.glow}/bin/glow --style dark --width 120 {}'
      elif command -v ${pkgs.bat}/bin/bat >/dev/null; then
        PREVIEW_CMD='${pkgs.bat}/bin/bat --style=numbers --color=always --line-range=:500 {}'
      else
        PREVIEW_CMD='sed -n "1,200p" -- {}'
      fi

      printf "%s\n" "''${LIST_CMD[@]}" | sort -f | ${pkgs.fzf}/bin/fzf --multi \
        --height=80% \
        --reverse \
        --prompt='notes> ' \
        --preview="$PREVIEW_CMD" \
        --preview-window=right,60%,border \
        --bind='ctrl-a:toggle-all' | \
      xargs -r -d '\n' ${pkgs.neovim}/bin/nvim
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
