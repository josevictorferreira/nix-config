{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      nodejs_24
      lua51Packages.lua
      lua51Packages.luarocks
      cargo
      rustc
    ];
  };
}
