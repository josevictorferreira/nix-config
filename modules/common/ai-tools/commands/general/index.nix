{ ... }:
{
  imports = [
    ./ask.nix
    ./do.nix
    ./implement-change.nix
    ./implement-feature.nix
    ./implement-fix.nix
    ./implement-refactoring.nix
    ./implement-tests.nix
  ];

  config = {
    # no-op; commands are pure data modules
  };
}
