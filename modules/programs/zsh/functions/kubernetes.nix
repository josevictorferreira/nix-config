{
  pkgs,
  ...
}:

let
  ksc = pkgs.writeShellApplication {
    name = "ksc";
    runtimeInputs = [
      pkgs.kubectl
      pkgs.fzf
    ];
    text = ''
      # Switch kubernetes contexts using fzf
      contexts=$(kubectl config get-contexts -o name)
      selected_context=$(echo "''${contexts}" | fzf)

      if [ -n "$selected_context" ]; then
        kubectl config use-context "$selected_context"
      else
        echo "No context selected."
      fi
    '';
  };
in
{
  packages = [ ksc ];
  shellInit = "";
}
