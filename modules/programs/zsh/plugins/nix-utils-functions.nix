{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "nix-utils-functions";
  src = pkgs.writeTextDir "nix-utils-functions.plugin.zsh" ''
    function nr() {
      nix run .#"$@"
    }

    # Initialize a sandbox template - usage: sandbox-init [template-name]
    # Without arguments, opens fzf to select from available templates
    sandbox-init() {
      local nix_config="$HOME/.config/nix"
      local template="$1"
      
      if [[ -z "$template" ]]; then
        # fzf mode - list and select templates (strip ANSI codes from nix flake show output)
        template=$(nix flake show "path:$nix_config" 2>/dev/null \
          | sed 's/\x1b\[[0-9;]*m//g' \
          | grep -E 'sandbox-' \
          | sed 's/.*───//' \
          | cut -d: -f1 \
          | fzf --prompt="Select sandbox template: " --height=40% --reverse)
        [[ -z "$template" ]] && echo "No template selected" && return 1
      fi
      
      nix flake init -t "path:$nix_config#$template" && \
        echo "Initialized '$template' template. Run 'nix develop --impure' to enter."
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
