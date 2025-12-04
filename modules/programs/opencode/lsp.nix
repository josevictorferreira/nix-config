{ lib, pkgs, ... }:
{
  config.jvf.programs.opencode.settings.lsp = {
    nixd = {
      command = [ (lib.getExe pkgs.nixd) ];
      extensions = [ ".nix" ];
      initialization = {
        formatting = {
          command = [ (lib.getExe pkgs.nixfmt) ];
        };
      };
    };

    emmylua-ls = {
      command = [ (lib.getExe pkgs.emmylua-ls) ];
      extensions = [ ".lua" ];
      initialization = {
        Lua = {
          diagnostics = {
            globals = [
              "vim"
              "Sbar"
              "spoon"
            ];
          };
        };
      };
    };

    pyright = {
      command = [ (lib.getExe pkgs.pyright) ];
      extensions = [
        ".py"
        ".pyi"
      ];
    };

    bashls = {
      command = [
        (lib.getExe pkgs.bash-language-server)
        "start"
      ];
      extensions = [
        ".sh"
        ".bash"
      ];
    };

    typescript = {
      command = [
        (lib.getExe pkgs.typescript-language-server)
        "--stdio"
      ];
      extensions = [
        ".ts"
        ".tsx"
        ".js"
        ".jsx"
        ".mjs"
        ".cjs"
        ".mts"
        ".cts"
      ];
    };

    gopls = {
      command = [ (lib.getExe pkgs.gopls) ];
      extensions = [
        ".go"
        ".mod"
        ".sum"
      ];
    };

    rust-analyzer = {
      command = [ (lib.getExe pkgs.rust-analyzer) ];
      extensions = [ ".rs" ];
    };

    yamlls = {
      command = [
        (lib.getExe pkgs.yaml-language-server)
        "--stdio"
      ];
      extensions = [
        ".yaml"
        ".yml"
      ];
    };

    jsonls = {
      command = [
        (lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server")
        "--stdio"
      ];
      extensions = [
        ".json"
        ".jsonc"
      ];
    };

    taplo = {
      command = [
        (lib.getExe pkgs.taplo)
        "lsp"
        "stdio"
      ];
      extensions = [ ".toml" ];
    };

    ruby-lsp = {
      command = [
        "bundle"
        "exec"
        "ruby-lsp"
        "stdio"
      ];
      extensions = [
        ".rb"
        "Gemfile"
        ".gemspec"
        ".ru"
        ".rake"
        ".rbs"
      ];
    };
  };
}
