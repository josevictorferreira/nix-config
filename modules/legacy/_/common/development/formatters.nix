{ pkgs, ... }:

{
  packages = [
    pkgs.stylua
    pkgs.prettier
    pkgs.nixfmt
    pkgs.nixpkgs-fmt
  ];
}
