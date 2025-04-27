{ pkgs, config, configRoot, ... }:

let
  k9sConfigDir = "${configRoot}/config/k9s";
in
{
  home = {
    file = {
      ".config/k9s" = {
        source = "${k9sConfigDir}";
        recursive = true;
        executable = false;
      };
    };
    packages = with pkgs; [
      k9s
    ];
    sessionVariables = {
      K9S_CONFIG_DIR = "${config.home.homeDirectory}/.config/k9s";
    };
  };
}
