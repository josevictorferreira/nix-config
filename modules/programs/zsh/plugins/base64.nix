{ pkgs, ... }:

let
  copyCmd = if pkgs.stdenv.isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";
in
pkgs.stdenv.mkDerivation {
  name = "zsh-base64";
  src = pkgs.writeTextDir "zsh-base64.plugin.zsh" ''
    function b64() {
      # Convert text to base64 and copy to clipboard
      if [ -z "$1" ]; then
        echo "Usage: b64 <text>" >&2
        return 1
      fi
      echo -n "$1" | ${pkgs.coreutils}/bin/base64 -w 0 | ${copyCmd}
    }

    function bb64() {
      # Decode base64
      if [ -z "$1" ]; then
        echo "Usage: bb64 <base64_string>" >&2
        return 1
      fi
      echo -n "$1" | ${pkgs.coreutils}/bin/base64 -d
    }
  '';

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
