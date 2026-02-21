{ pkgs, ... }:

{
  packages = [
    pkgs.nodejs_24
    pkgs.lua51Packages.lua
    pkgs.lua51Packages.luarocks
    pkgs.cargo
    pkgs.rustc
  ];
}
