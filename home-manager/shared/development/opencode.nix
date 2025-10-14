{
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    opencode
  ];

  programs.opencode = {
    enable = true;

    settings = {
      theme = "one-dark";
      model = "moonshotai/kimi-k2-0905";
      autoshare = false;
      autoupdate = false;
      provider = {
        openrouter = {
          models = {
            "z-ai/glm-4.6" = {
              name = "GLM 4.6";
            };
            "x-ai/grok-4-fast" = {
              name = "Grok 4 Fast";
            };
            "moonshotai/kimi-k2-0905" = {
              name = "Kimi K2 Instruct 0905";
            };
            "google/gemini-2.5-pro" = {
              name = "Gemini 2.5 Pro";
            };
          };
        };
      };
      mcp = {
        github = {
          type = "local";
          command = [
            (lib.getExe pkgs.github-mcp-server)
            "--read-only"
            "stdio"
          ];
          enabled = false;
        };
        socket = {
          type = "remote";
          url = "https://mcp.socket.dev/";
          enabled = false;
        };
      };

      lsp = {
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
      };

      formatter = {
        nixfmt = {
          command = [
            (lib.getExe pkgs.nixfmt)
            "$FILE"
          ];
          extensions = [ ".nix" ];
        };

        rustfmt = {
          command = [
            (lib.getExe pkgs.rustfmt)
            "$FILE"
          ];
          extensions = [ ".rs" ];
        };
      };

      permission = {
        edit = "ask";
        bash = {
          "git status*" = "allow";
          "git log*" = "allow";
          "git diff*" = "allow";
          "git show*" = "allow";
          "git branch*" = "allow";
          "git remote*" = "allow";
          "git config*" = "allow";
          "git rev-parse*" = "allow";
          "git ls-files*" = "allow";
          "git ls-remote*" = "allow";
          "git describe*" = "allow";
          "git tag --list*" = "allow";
          "git blame*" = "allow";
          "git shortlog*" = "allow";
          "git reflog*" = "allow";
          "git add*" = "allow";

          # Safe Nix commands
          "nix search*" = "allow";
          "nix eval*" = "allow";
          "nix show-config*" = "allow";
          "nix flake show*" = "allow";
          "nix flake check*" = "allow";
          "nix log*" = "allow";

          # Safe file system operations
          "ls*" = "allow";
          "pwd*" = "allow";
          "find*" = "allow";
          "grep*" = "allow";
          "rg*" = "allow";
          "cat*" = "allow";
          "head*" = "allow";
          "tail*" = "allow";
          "mkdir*" = "allow";
          "chmod*" = "allow";

          # Safe system info commands
          "systemctl list-units*" = "allow";
          "systemctl list-timers*" = "allow";
          "systemctl status*" = "allow";
          "journalctl*" = "allow";
          "dmesg*" = "allow";
          "env*" = "allow";
          "nh search*" = "allow";

          # Audio system (read-only)
          "pactl list*" = "allow";
          "pw-top*" = "allow";

          # Potentially destructive git commands
          "git reset*" = "ask";
          "git commit*" = "ask";
          "git push*" = "ask";
          "git pull*" = "ask";
          "git merge*" = "ask";
          "git rebase*" = "ask";
          "git checkout*" = "ask";
          "git switch*" = "ask";
          "git stash*" = "ask";

          # File deletion and modification
          "rm*" = "ask";
          "mv*" = "ask";
          "cp*" = "ask";

          # System control operations
          "systemctl start*" = "ask";
          "systemctl stop*" = "ask";
          "systemctl restart*" = "ask";
          "systemctl reload*" = "ask";
          "systemctl enable*" = "ask";
          "systemctl disable*" = "ask";

          # Network operations
          "curl*" = "ask";
          "wget*" = "ask";
          "ping*" = "ask";
          "ssh*" = "ask";
          "scp*" = "ask";
          "rsync*" = "ask";

          # Package management
          "sudo*" = "ask";
          "nixos-rebuild*" = "ask";

          # Process management
          "kill*" = "ask";
          "killall*" = "ask";
          "pkill*" = "ask";
        };
        read = "allow";
        list = "allow";
        glob = "allow";
        grep = "allow";
        webfetch = "ask";
        write = "ask";
        task = "allow";
        todowrite = "allow";
        todoread = "allow";
      };
    };
  };
}
