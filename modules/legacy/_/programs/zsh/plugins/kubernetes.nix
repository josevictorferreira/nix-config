{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "zsh-kubernetes";
  src = pkgs.writeTextDir "zsh-kubernetes.plugin.zsh" ''
    function ksc() {
      local contexts selected_context
      contexts=$(${pkgs.kubectl}/bin/kubectl config get-contexts -o name)
      selected_context=$(echo "''${contexts}" | ${pkgs.fzf}/bin/fzf)

      if [ -n "$selected_context" ]; then
        ${pkgs.kubectl}/bin/kubectl config use-context "$selected_context"
      else
        echo "No context selected."
      fi
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
