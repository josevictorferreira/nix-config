{ pkgs
, config
, ...
}:

let
  cfg = config.jvf.programs.zsh;
  fallbackTodo = "${cfg.workspace.shared}/notetaking/checklists/todo.md";
in
pkgs.stdenv.mkDerivation {
  name = "zsh-todo";
  src = pkgs.writeTextDir "zsh-todo.plugin.zsh" ''
    function todo() {
      local fallback_file="${fallbackTodo}"
      local git_root todo_file

      # Try to find git root
      git_root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)

      if [[ -n "$git_root" ]]; then
        # Check for existing TODO.md or .docs/TODO.md
        if [[ -f "$git_root/TODO.md" ]]; then
          todo_file="$git_root/TODO.md"
        elif [[ -f "$git_root/.docs/TODO.md" ]]; then
          todo_file="$git_root/.docs/TODO.md"
        else
          # Create .docs/TODO.md if neither exists
          ${pkgs.coreutils}/bin/mkdir -p "$git_root/.docs"
          todo_file="$git_root/.docs/TODO.md"
          if [[ ! -f "$todo_file" ]]; then
            echo "# TODO" > "$todo_file"
            echo "" >> "$todo_file"
            echo "Created: $(date +%Y-%m-%d)" >> "$todo_file"
            echo "" >> "$todo_file"
          fi
        fi
      else
        # Fallback: no git repo found
        todo_file="$fallback_file"
        # Ensure fallback directory exists
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$todo_file")"
        if [[ ! -f "$todo_file" ]]; then
          echo "# TODO" > "$todo_file"
          echo "" >> "$todo_file"
          echo "Created: $(date +%Y-%m-%d)" >> "$todo_file"
          echo "" >> "$todo_file"
        fi
      fi

      ${pkgs.neovim}/bin/nvim "$todo_file"
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
