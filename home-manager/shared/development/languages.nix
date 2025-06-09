{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      luajit
      luajitPackages.luarocks
    ];
  };
}
