{ lib
, pkgs
, config
, ...
}:

let
  run-livebook = pkgs.writeShellApplication {
    name = "run-livebook";
    runtimeInputs = [ pkgs.docker ];
    text = ''
      # Automatically creates and runs a phoenix livebook container
      docker run -p 8080:8080 --pull always \
        -u "$(id -u):$(id -g)" -v "$(pwd):/data" livebook/livebook
    '';
  };

  b64 = pkgs.writeShellApplication {
    name = "b64";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.wl-clipboard
    ];
    text = ''
      # Convert text to base64 and copy to clipboard
      if [ -z "$1" ]; then
        echo "Usage: b64 <text>" >&2
        exit 1
      fi
      echo -n "$1" | base64 -w 0 | wl-copy
    '';
  };

  bb64 = pkgs.writeShellApplication {
    name = "bb64";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # Decode base64
      if [ -z "$1" ]; then
        echo "Usage: bb64 <base64_string>" >&2
        exit 1
      fi
      echo -n "$1" | base64 -d
    '';
  };
in
{
  packages = [
    run-livebook
    b64
    bb64
  ];
  functions = ''
    # Legacy alias for backward compatibility
    alias run_livebook="run-livebook"
  '';
}
