{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "zsh-run-livebook";
  src = pkgs.writeTextDir "zsh-run-livebook.plugin.zsh" ''
    function run-livebook() {
      # Automatically creates and runs a phoenix livebook container
      ${pkgs.docker}/bin/docker run -p 8080:8080 --pull always \
        -u "$(id -u):$(id -g)" -v "$(pwd):/data" livebook/livebook
    }

    # Legacy alias for backward compatibility
    alias run_livebook="run-livebook"
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
