{ pkgs, configRoot, ... }:

let
  neovimConfigDir = "${configRoot}/config/nvim";
in
{
  imports = [
    ./development/lsp-servers.nix
    ./development/formatters.nix
    ./development/languages.nix
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = false;
    vimAlias = false;
    extraLuaConfig = builtins.readFile "${neovimConfigDir}/init.lua";
  };

  home = {
    packages = with pkgs; [
      fzf
      ripgrep
      fd
    ];

    file = {
      ".config/nvim/lua" =
        {
          source = "${neovimConfigDir}/lua";
          recursive = true;
          executable = false;
        };
      ".config/nvim/schemas" =
        {
          source = "${neovimConfigDir}/schemas";
          recursive = true;
          executable = false;
        };
      ".config/nvim/after" =
        {
          source = "${neovimConfigDir}/after";
          recursive = true;
          executable = false;
        };
    };
  };
}
