{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      rust-analyzer
      bash-language-server
      lua-language-server
      vscode-langservers-extracted # cssls, html, jsonls, eslint, markdown
      dockerfile-language-server-nodejs
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
      emmet-ls
      nixd
      helm-ls
      gopls
      autotools-language-server
    ];
  };
}
