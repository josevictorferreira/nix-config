{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "nix-utils-functions";
  src = pkgs.writeTextDir "nix-utils-functions.plugin.zsh" ''
    function nr() {
      nix run .#"$@"
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
