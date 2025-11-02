{ pkgs, ... }:

{
  packages = [
    pkgs.rust-analyzer
    pkgs.bash-language-server
    pkgs.lua-language-server
    pkgs.vscode-langservers-extracted
    pkgs.dockerfile-language-server
    pkgs.docker-compose-language-service
    pkgs.ruff
    pkgs.vim-language-server
    pkgs.yaml-language-server
    pkgs.gleam
    pkgs.dot-language-server
    pkgs.jdt-language-server
    pkgs.crystalline
    pkgs.tailwindcss-language-server
    pkgs.ruby-lsp
    pkgs.protols
    pkgs.typescript-language-server
    pkgs.emmet-ls
    pkgs.nixd
    pkgs.helm-ls
    pkgs.gopls
    pkgs.autotools-language-server
  ];
}
