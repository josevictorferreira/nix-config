{ lib
, pkgs
, config
, ...
}:

{
  functions = ''
    # Automatically creates and runs a phoenix livebook container
    function run_livebook() {
      ${pkgs.docker}/bin/docker run -p 8080:8080 --pull always \
        -u $(id -u):$(id -g) -v $(pwd):/data livebook/livebook
    }

    # Convert text to base64 and copy to clipboard
    function b64() {
      echo -n "$1" | ${pkgs.coreutils}/bin/base64 -w 0 | ${pkgs.wl-clipboard}/bin/wl-copy
    }

    # Decode base64
    function bb64() {
      echo -n "$1" | ${pkgs.coreutils}/bin/base64 -d
    }
  '';
}
