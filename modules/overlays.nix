# perSystem aspect: pkgs policy (overlays + allowUnfree)
# Provides _module.args.pkgs for all perSystem modules (formatter, devShells, etc.)
# Selects nixpkgs vs nixpkgs-darwin based on system.
{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      isDarwin = builtins.match ".*-darwin" system != null;
      pkgs = import (if isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs) {
        inherit system;
        overlays = [ inputs.bun2nix.overlays.default ];
        config.allowUnfree = true;
      };
    in
    {
      _module.args.pkgs = pkgs;

      # Formatter (must remain accessible via `nix fmt`)
      formatter = pkgs.nixpkgs-fmt;

      # Statix lint check - ensures codebase is always linted
      checks.statix = pkgs.stdenv.mkDerivation {
        name = "statix-check";
        src = ../.;
        nativeBuildInputs = [ pkgs.statix ];
        buildPhase = ''
          statix check . 2>&1 | tee $out
        '';
        installPhase = ''
          mkdir -p $out
          echo "Statix check passed" > $out/result
        '';
      };
    };
}
