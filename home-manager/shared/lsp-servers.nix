{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      rust-analyzer
      bash-language-server
      lua-language-server
      cmake-language-server
      css-lsp
      vscode-langservers-extracted # cssls, html, jsonls, eslint, markdown
      docker-language-server
      docker-compose-language-service
      ruff
      vim-language-server
      yaml-language-server
      gleam
      dot-language-server
      jdt-language-server
      crystalline
      tailwindcss-language-server
      ruby-lsp
      protols
      typescript-language-server
      emmet-language-server
      nixd
      helm-ls
    ];
  };
}
