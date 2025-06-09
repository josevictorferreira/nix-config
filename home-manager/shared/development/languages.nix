{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      lua51Packages.lua
      lua51Packages.luarocks
      cargo
      rustc
    ];
  };
}
