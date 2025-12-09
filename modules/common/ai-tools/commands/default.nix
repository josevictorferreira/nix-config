{ ... }:
{
  imports = [
    ./git/default.nix
    ./nix/index.nix
    ./general/default.nix
    ./quality/default.nix
    ./project/default.nix
  ];
}
