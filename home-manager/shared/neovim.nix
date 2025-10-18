{
  pkgs,
  configRoot,
  isDarwin,
  ...
}:

let
  neovimConfigDir = "${configRoot}/dotfiles/nvim";
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
    packages = [
      pkgs.fzf
      pkgs.ripgrep
      pkgs.fd
      pkgs.gcc
      pkgs.tree-sitter
      pkgs.pkg-config
    ]
    ++ (
      if (!isDarwin) then
        [
          pkgs.glibc
          pkgs.glibc.dev
        ]
      else
        [ ]
    );

    file = {
      ".config/nvim/lua" = {
        source = "${neovimConfigDir}/lua";
        recursive = true;
        executable = false;
      };
      ".config/nvim/schemas" = {
        source = "${neovimConfigDir}/schemas";
        recursive = true;
        executable = false;
      };
      ".config/nvim/after" = {
        source = "${neovimConfigDir}/after";
        recursive = true;
        executable = false;
      };
    };
  };
}
