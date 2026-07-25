# Aspect: programs-neovim
# Installs neovim + development tooling (LSP servers, formatters, languages).
# NixOS-only: glibc, glibc.dev.
# Clones .nvim config repo via jvf.repositories.
_:
let
  mkNeovimOptions =
    { config, lib, ... }:
    {
      options.jvf.programs.neovim = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };
      };
    };

  neovimModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.neovim;

      # Theme-aware wrapper for neovim
      nvimWrapper = pkgs.writeShellScriptBin "nvim" ''
        # Read current JVF theme and export for nvim config
        if [ -f "$HOME/.local/state/jvf-theme/env" ]; then
          source "$HOME/.local/state/jvf-theme/env"
        fi
        # Fallback if env file doesn't exist
        if [ -z "''${JVF_THEME:-}" ]; then
          JVF_THEME="dark"
        fi
        export JVF_THEME
        exec ${pkgs.neovim}/bin/nvim "$@"
      '';

      # Development tools (inlined from deleted legacy module)
      lspServers = [
        pkgs.rust-analyzer
        pkgs.bash-language-server
        pkgs.lua-language-server
        pkgs.luau-lsp
        pkgs.vscode-langservers-extracted
        pkgs.dockerfile-language-server
        pkgs.docker-compose-language-service
        pkgs.ruff
        pkgs.vim-language-server
        pkgs.yaml-language-server
        pkgs.gleam
        pkgs.dot-language-server
        pkgs.jdt-language-server
        pkgs.tailwindcss-language-server
        pkgs.ruby-lsp
        pkgs.protols
        pkgs.typescript-language-server
        pkgs.emmet-ls
        pkgs.nixd
        pkgs.helm-ls
        pkgs.gopls
        pkgs.tinymist
        pkgs.autotools-language-server
      ];

      formatters = [
        pkgs.stylua
        pkgs.prettier
        pkgs.nixfmt
        pkgs.nixpkgs-fmt
      ];

      languages = [
        pkgs.nodejs_24
        pkgs.lua51Packages.lua
        pkgs.lua51Packages.luarocks
        pkgs.cargo
        pkgs.rustc
      ];
    in
    {
      imports = [ mkNeovimOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          nvimWrapper
          pkgs.fzf
          pkgs.ripgrep
          pkgs.fd
          pkgs.gcc
          pkgs.tree-sitter
          pkgs.pkg-config
          pkgs.openssh
          pkgs.cmake
        ]
        ++ lspServers
        ++ formatters
        ++ languages
        ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
          pkgs.glibc
          pkgs.glibc.dev
        ]);

        jvf.repositories.users.${cfg.username}.clonedDirs = {
          ".config/nvim" = "git@github.com:josevictorferreira/.nvim.git";
        };
      };
    };
in
{
  flake.modules.nixos.programs-neovim = neovimModule;
  flake.modules.darwin.programs-neovim = neovimModule;
}
