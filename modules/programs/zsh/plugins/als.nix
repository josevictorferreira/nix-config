{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "zsh-als";
  src = pkgs.writeTextDir "zsh-als.plugin.zsh" ''
    # Interactive alias selection and execution
    function als() {
      local cmd
      cmd=$(alias | sed "s/^alias //" | \
        ${pkgs.fzf}/bin/fzf --ansi --height 20 \
          --preview "echo {}" | \
        ${pkgs.gawk}/bin/awk -F'=' '{print $2}' | tr -d "'")
      if [[ -n $cmd ]]; then
        eval "$cmd"
      fi
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
