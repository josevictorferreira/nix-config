# perSystem aspect: pkgs policy (overlays + allowUnfree)
# Provides _module.args.pkgs for all perSystem modules (formatter, devShells, etc.)
# Selects nixpkgs vs nixpkgs-darwin based on system.
{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      isDarwin = builtins.match ".*-darwin" system != null;
      pkgsBase = import (if isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs) {
        inherit system;
        overlays = [ inputs.bun2nix.overlays.default ];
      };
    in
    {
      _module.args.pkgs = pkgsBase;

      # Formatter (must remain accessible via `nix fmt`)
      formatter = pkgsBase.nixpkgs-fmt;

      # Statix lint check - ensures codebase is always linted
      checks.statix = pkgsBase.stdenv.mkDerivation {
        name = "statix-check";
        src = ../.;
        nativeBuildInputs = [ pkgsBase.statix ];
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
