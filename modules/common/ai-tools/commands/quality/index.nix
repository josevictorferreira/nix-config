{ ... }:
{
  imports = [
    ./quick-check.nix
    ./deep-check.nix
    ./style-audit.nix
    ./dependency-audit.nix
    ./module-lint.nix
  ];
}
