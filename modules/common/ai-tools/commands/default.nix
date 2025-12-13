{ ... }:
{
  imports = [
    ./git/add-and-format.nix
    ./git/commit-changes.nix
    ./general/deep-check.nix
    ./general/dependency-audit.nix
    ./general/style-audit.nix
    ./implementation/implement-change.nix
    ./implementation/implement-feature.nix
    ./implementation/implement-fix.nix
    ./implementation/implement-refactoring.nix
    ./implementation/implement-tests.nix
    ./nix/flake-update.nix
    ./nix/nix-check.nix
    ./nix/nix-module-lint.nix
    ./nix/nix-module-scaffold.nix
    ./nix/nix-option-migrate.nix
    ./nix/nix-refactor.nix
    ./nix/nix-template-new.nix
  ];
}
