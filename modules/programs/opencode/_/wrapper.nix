# wrapper.nix - FHS environment and wrapper scripts for OpenCode
{ pkgs, version }:
let
  openCodeFHS = pkgs.buildFHSEnv {
    name = "opencode-fhs";
    targetPkgs =
      pkgs: with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        ripgrep
        coreutils
        git
        gh
        bun
        nodejs
      ];
    profile = ''
      export TMPDIR="''${TMPDIR:-$HOME/.cache/opencode-tmp}"
      mkdir -p "$TMPDIR"
    '';
    runScript = "${pkgs.writeShellScript "opencode-runner" ''
      exec "$HOME/.opencode/bin/opencode" "$@"
    ''}";
  };

  # Pinned install: always passes --version to the installer so it never calls
  # GitHub's unauthenticated /releases/latest API. Bump `jvf.programs.opencode.version`
  # and rebuild to upgrade; set OPENCODE_UPDATE=true to force a manual reinstall.
  # After a successful install, we stamp .installed-version so the wrapper can
  # tell on later launches whether the declared version has drifted.
  installScript = ''
    PATH="$LOCAL_BIN:$PATH" "${pkgs.bash}/bin/sh" -c \
      "$(${pkgs.curl}/bin/curl -fsSL "$INSTALL_URL")" \
      opencode-installer --version ${version}
    printf '%s' "${version}" > "$HOME/.opencode/.installed-version"
  '';

  # Self-healing version check: reinstall whenever the declared version diverges
  # from the marker file written at the end of a successful install. This keeps
  # the 142 MB opencode binary across rebuilds that only touch plugins/config,
  # and only triggers a fresh download on an actual `version` bump.
  #
  # _OPENCODE_WRAPPER_INSTALLING is a recursion guard: the upstream installer's
  # check_version() shells out to `opencode --version` via PATH, which hits this
  # wrapper. Without the guard that call would re-enter the install branch and
  # fork-bomb. When set and the binary isn't in place yet we exit silently so
  # check_version treats it as "not installed".
  reinstallGuard = ''
    if [ -z "''${_OPENCODE_WRAPPER_INSTALLING:-}" ]; then
      declared="${version}"
      installed=""
      if [ -r "$HOME/.opencode/.installed-version" ]; then
        installed=$(cat "$HOME/.opencode/.installed-version")
      fi
      if [ ! -x "$OPENCODE_BIN" ] \
        || [ "$installed" != "$declared" ] \
        || [ "''${OPENCODE_UPDATE:-}" = "true" ]; then
        mkdir -p "$LOCAL_BIN"
        export _OPENCODE_WRAPPER_INSTALLING=1
        ${installScript}
        unset _OPENCODE_WRAPPER_INSTALLING
      fi
    fi

    if [ -n "''${_OPENCODE_WRAPPER_INSTALLING:-}" ] && [ ! -x "$OPENCODE_BIN" ]; then
      exit 1
    fi
  '';

  shellScriptBinLinux = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    INSTALL_URL="https://opencode.ai/install"
    LOCAL_BIN="$HOME/.opencode/bin"
    OPENCODE_BIN="$LOCAL_BIN/opencode"

    ${reinstallGuard}

    exec "${openCodeFHS}/bin/opencode-fhs" "$@"
  '';

  shellScriptBinDarwin = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    INSTALL_URL="https://opencode.ai/install"
    LOCAL_BIN="$HOME/.opencode/bin"
    OPENCODE_BIN="$LOCAL_BIN/opencode"

    ${reinstallGuard}

    exec "$OPENCODE_BIN" "$@"
  '';
in
{
  inherit shellScriptBinLinux shellScriptBinDarwin;
}
