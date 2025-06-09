{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      stylua
      nixpkgs-fmt
      prettier
    ];
  };
}
