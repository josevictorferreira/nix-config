{ pkgs, ... }:

{
  packages = [
    pkgs.stylua
    pkgs.prettier
    pkgs.nixpkgs-fmt
  ];
}
