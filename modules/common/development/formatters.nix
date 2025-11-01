{ pkgs, ... }:

{
  packages = [
    pkgs.stylua
    pkgs.prettier
    pkgs.nixfmt
  ];
}
