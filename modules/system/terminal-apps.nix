# Aspect: system-terminal-apps
# Links Nix-managed terminal .app bundles into /Applications so that
# Launchpad, Spotlight, and `open` find the same binaries that Nix provides.
#
# Scope: ONLY symlinks kitty and ghostty. We intentionally do not enable
# services.nix-darwin.linkApps (which would expose every package's .app
# blindly — e.g. random dev tools). If you add another Nix-managed terminal,
# add an entry below.
_:
let
  # Shared identity: extract the macOS primary user from the host's jvf.core.
  # We don't use jvf.core.username as default to keep this file standalone,
  # but we read primaryUser from system.primaryUser which the host sets.
  mkTerminalApps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Pull the package from each program module if exposed; otherwise fall
      # back to the nixpkgs default. The program modules own the version
      # pin, so we just read jvf.programs.<name>.package.
      kittyPkg = config.jvf.programs.kitty.package or pkgs.kitty;
      ghosttyPkg = config.jvf.programs.ghostty.package or pkgs.ghostty-bin;

      linkApp = name: src:
        let dst = "/Applications/${name}.app"; in
        ''
          # Idempotent: remove any existing entry (file/dir/symlink) at $dst
          # so we don't conflict with a manually-installed bundle of the same name.
          if [ -e "${dst}" ] || [ -L "${dst}" ]; then
            echo "[terminal-apps] Removing existing ${dst}"
            rm -rf "${dst}"
          fi
          # Create a symlink in /Applications pointing at the nix store .app.
          # The symlink target is the package's Applications/<name>.app subpath.
          echo "[terminal-apps] Linking ${dst} -> ${src}"
          ln -s "${src}" "${dst}"
        '';
    in
    {
      # Activation script runs after nix-darwin's standard 'applications' phase
      # (which sets up /Applications/Nix Apps/). We use 'extraActivation' so our
      # custom script gets inlined into the activate script — nix-darwin only
      # inlines a fixed list of named activation scripts, and a custom key like
      # 'terminalApps' would be silently dropped. extraActivation runs after
      # 'createRun' but before 'applications' (the rsync of /Applications/Nix
      # Apps/), so the symlinks we create are not clobbered.
      system.activationScripts.extraActivation.text = lib.concatStringsSep "\n" [
        (linkApp "kitty" "${kittyPkg}/Applications/kitty.app")
        (linkApp "Ghostty" "${ghosttyPkg}/Applications/Ghostty.app")
      ];

      # Belt-and-suspenders: also expose the binaries on PATH (wrappers does
      # this too, but a direct systemPackages entry survives wrappers bugs).
      environment.systemPackages = [
        kittyPkg
        ghosttyPkg
      ];
    };
in
{
  flake.modules.nixos.system-terminal-apps = mkTerminalApps;
  flake.modules.darwin.system-terminal-apps = mkTerminalApps;
}
