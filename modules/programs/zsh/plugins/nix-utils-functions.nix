{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "nix-utils-functions";
  src = pkgs.writeTextDir "nix-utils-functions.plugin.zsh" ''
    function nr() {
      nix run .#"$@"
    }

    # Initialize from any flake template in ~/.config/nix
    # Usage: flake-init [template-name]
    # Without args, opens fzf to select from available templates
    flake-init() {
      local nix_config="$HOME/.config/nix"
      local template="$1"

      if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required for flake-init" >&2
        return 1
      fi

      if [[ -z "$template" ]]; then
        # fzf mode - list and select templates from the flake
        template=$(nix flake show "path:$nix_config" --json 2>/dev/null \
          | jq -r '.templates // {} | keys[]' \
          | fzf --prompt="Select flake template: " --height=40% --reverse)
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
