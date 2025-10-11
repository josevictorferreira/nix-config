{ pkgs, configRoot, ... }:

{
  home = {
    packages = with pkgs; [
      claude-code
    ];
  };
}
