# Aspect: programs-opencode
# Defines jvf.programs.opencode options for OpenCode AI coding tool.
# NixOS: FHS environment wrapper for glibc compatibility + config via wrappers.
# Darwin: direct execution + config via wrappers.
{ ... }:
let
  mkOpencodeOptions =
    { lib, ... }:
    let
      json = lib.formats.json { };
    in
    {
      options.jvf.programs.opencode = {
        enable = lib.mkEnableOption "Install opencode and write per-user ~/.config/opencode/config.json";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to install the configuration";
        };

        baseRules = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "A set of base rules to apply to the OpenCode configuration.";
        };

        agents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Agents to install into the configuration (string prompts or structured objects)";
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Skills to install into the configuration (string prompts or structured objects)";
        };

        commands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str json.type);
          default = { };
          description = "Commands to install into the configuration (string prompts or structured objects)";
        };

        mcps = lib.mkOption {
          type = lib.types.attrsOf json.type;
          default = { };
          description = "MCP tools to install into the configuration (structured objects)";
        };

        ohMyOpenCodeSettings = lib.mkOption {
          type = json.type;
          default = { };
          description = "Settings written to ~/.config/opencode/oh-my-opencode.json";
        };

        settings = lib.mkOption {
          type = json.type;
          default = { };
          description = "Settings written to ~/.config/opencode/config.json";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.jvf.programs.opencode;
      json = pkgs.formats.json { };

      openCodeFHS = pkgs.buildFHSEnv {
        name = "opencode-fhs";
        targetPkgs =
          pkgs: with pkgs; [
            stdenv.cc.cc.lib
            zlib
            openssl
            curl
            ripgrep
            coreutils
          ];
        profile = ''
          export TMPDIR="''${TMPDIR:-$HOME/.cache/opencode-tmp}"
          mkdir -p "$TMPDIR"
        '';
        runScript = "${pkgs.writeShellScript "opencode-runner" ''
          exec "$HOME/.opencode/bin/opencode" "$@"
        ''}";
      };

      shellScriptBinLinux = pkgs.writeShellScriptBin "opencode" ''
        set -euo pipefail

        INSTALL_URL="https://opencode.ai/install"
        OPENCODE_BIN_DIR="$HOME/.opencode/bin"

        if [ ! -x "$OPENCODE_BIN_DIR/opencode" ]; then
          mkdir -p "$OPENCODE_BIN_DIR"
          PATH="$OPENCODE_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
        fi

        exec "${openCodeFHS}/bin/opencode-fhs" "$@"
      '';

      shellScriptBinDarwin = pkgs.writeShellScriptBin "opencode" ''
        set -euo pipefail

        INSTALL_URL="https://opencode.ai/install"
        OPENCODE_BIN_DIR="$HOME/.opencode/bin"
        OPENCODE_BIN="$OPENCODE_BIN_DIR/opencode"

        if [ ! -x "$OPENCODE_BIN" ]; then
          mkdir -p "$OPENCODE_BIN_DIR"
          PATH="$OPENCODE_BIN_DIR:$PATH" "${pkgs.bash}/bin/sh" -c "$(${pkgs.curl}/bin/curl -fsSL $INSTALL_URL)"
        fi

        exec "$OPENCODE_BIN" "$@"
      '';
    in
    {
      imports = [ mkOpencodeOptions ];

      config = lib.mkIf cfg.enable {
        # ── Default settings ──────────────────────────────────────────────
        jvf.programs.opencode.settings = {
          theme = lib.mkDefault "one-dark";
          mcp = lib.mkDefault cfg.mcps;
          disabled_providers = lib.mkDefault [
            "opencode"
            "copilot"
            "github-copilot-enterprise"
            "copilot-enterprise"
            "github-models"
            "minimax-cn"
          ];

          instructions = [
            ".docs/rules.md"
          ];

          tools = lib.mkDefault (
            builtins.listToAttrs (
              map (name: {
                name = "${name}*";
                value = false;
              }) (builtins.attrNames cfg.mcps)
            )
          );

          watcher = {
            ignore = [
              "node_modules/**"
              "dist/**"
              ".git/**"
              "build/**"
              ".bundle/**"
              "__pycache__/**"
              ".ck/**"
            ];
          };

          model = "zai-coding-plan/glm-4.7:fast";
          small_model = "copilot/grok-code-fast-1";

          # ── Formatters (from formatters.nix) ──────────────────────────
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

            dockerfmt = {
              command = [
                (lib.getExe pkgs.dockerfmt)
              ];
              extensions = [
                ".dockerfile"
                "Dockerfile"
                "Containerfile"
                "*Dockerfile*"
                "*Containerfile*"
              ];
            };

            ruff = {
              command = [
                "uv"
                "run"
                "ruff"
                "check"
                "--fix"
              ];
              extensions = [
                ".py"
                ".pyi"
              ];
            };

            rubocop = {
              command = [
                "bundle"
                "exec"
                "rubocop"
                "-A"
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

          # ── Permission (from permission.nix) ──────────────────────────
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

              "nix search*" = "allow";
              "nix eval*" = "allow";
              "nix show-config*" = "allow";
              "nix flake show*" = "allow";
              "nix flake check*" = "allow";
              "nix log*" = "allow";

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

              "systemctl list-units*" = "allow";
              "systemctl list-timers*" = "allow";
              "systemctl status*" = "allow";
              "journalctl*" = "allow";
              "dmesg*" = "allow";
              "env*" = "allow";
              "nh search*" = "allow";

              "pactl list*" = "allow";
              "pw-top*" = "allow";

              "git reset*" = "ask";
              "git commit*" = "ask";
              "git push*" = "ask";
              "git pull*" = "ask";
              "git merge*" = "ask";
              "git rebase*" = "ask";
              "git checkout*" = "ask";
              "git switch*" = "ask";
              "git stash*" = "ask";

              "rm*" = "ask";
              "mv*" = "ask";
              "cp*" = "ask";

              "systemctl start*" = "ask";
              "systemctl stop*" = "ask";
              "systemctl restart*" = "ask";
              "systemctl reload*" = "ask";
              "systemctl enable*" = "ask";
              "systemctl disable*" = "ask";

              "curl*" = "ask";
              "wget*" = "ask";
              "ping*" = "ask";
              "ssh*" = "ask";
              "scp*" = "ask";
              "rsync*" = "ask";

              "sudo*" = "ask";
              "nixos-rebuild*" = "ask";

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

          # ── LSP (from lsp.nix) ────────────────────────────────────────
          lsp = {
            nixd = {
              command = [ (lib.getExe pkgs.nixd) ];
              extensions = [ ".nix" ];
              initialization = {
                formatting = {
                  command = [ (lib.getExe pkgs.nixpkgs-fmt) ];
                };
              };
            };

            lua-ls.disabled = true;

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
              disabled = true;
            };

            pylsp = {
              command = [
                "uv"
                "run"
                "pylsp"
              ];
              extensions = [
                ".py"
                ".pyi"
              ];
            };

            ruff = {
              command = [
                "uv"
                "run"
                "ruff"
                "server"
              ];
              extensions = [
                ".py"
                ".pyi"
              ];
            };

            bash = {
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

            yaml-ls = {
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

            dockerls = {
              command = [ "${pkgs.docker-ls}/bin/docker-ls" ];
              extensions = [
                ".dockerfile"
                "Dockerfile"
                "Containerfile"
                "*Dockerfile*"
                "*Containerfile*"
              ];
            };

            sorbet = {
              command = [
                "bundle"
                "exec"
                "srb"
                "tc"
                "--lsp"
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

          # ── Provider (from provider.nix) ───────────────────────────────
          provider = {
            local = {
              npm = "@ai-sdk/openai-compatible";
              name = "Local";
              options = {
                baseURL = "http://10.10.10.10:1234/v1";
              };
              models = {
                "nvidia_orchestrator-8b" = {
                  name = "NVIDIA Orchestrator 8B";
                };
              };
            };

            openrouter = {
              npm = "@ai-sdk/anthropic";
              name = "OpenRouter";
              options = {
                baseURL = "https://openrouter.ai/api/v1";
                apiKey = "{env:OPENROUTER_API_KEY_CODE_AGENT}";
              };
              models = {
                "xiaomi/mimo-v2-flash" = {
                  name = "Xiaomi Mimo V2 Flash";
                };
              };
            };

            minimax = {
              npm = "@ai-sdk/anthropic";
              name = "Minimax";
              options = {
                baseURL = "https://api.minimax.io/anthropic/v1";
                apiKey = "{env:MINIMAX_API_KEY}";
              };
              models = {
                "MiniMax-M2" = {
                  name = "Minimax M2";
                };
                "MiniMax-M2.1" = {
                  name = "Minimax M2.1";
                };
                "MiniMax-M2.5" = {
                  name = "Minimax M2.5";
                };
              };
            };

            moonshotai = {
              npm = "@ai-sdk/anthropic";
              name = "Moonshot AI";
              options = {
                baseURL = "https://api.moonshot.ai/anthropic";
                apiKey = "{env:KIMI_API_KEY}";
              };
            };

            zai-coding-plan = {
              # npm = "@ai-sdk/anthropic";
              npm = "@ai-sdk/openai-compatible";
              options = {
                baseURL = "https://api.z.ai/api/coding/paas/v4";
                # baseURL = "https://api.z.ai/api/paas/v4/chat/completions";
                # baseURL = "https://api.z.ai/api/anthropic/v1";
                apiKey = "{env:Z_AI_API_KEY}";
              };
              models = {
                "glm-5" = {
                  name = "GLM-5";
                  variants = {
                    thinker = {
                      name = "GLM-5 Deep Thinker";
                      reasoningEffort = "high";
                      thinking = {
                        type = "enabled";
                        # clear_thinking = false;
                        # thinkingBudget = 32768;
                      };
                      max_tokens = 4096;
                      temperature = 1.0;
                    };
                    fast = {
                      name = "GLM-5 Fast";
                      reasoningEffort = "low";
                      textVerbosity = "low";
                      thinking.type = "disabled";
                      temperature = 0.1;
                      clear_thinking = false;
                    };
                  };
                };
                "glm-4.7" = {
                  name = "GLM-4.7";
                  variants = {
                    thinker = {
                      name = "GLM-4.7 Deep Thinker";
                      reasoningEffort = "high";
                      thinking.type = "enabled";
                      fast.disabled = true;
                      max_tokens = 4096;
                      temperature = 1.0;
                      clear_thinking = false;
                    };
                    fast = {
                      name = "GLM-4.7 Fast";
                      reasoningEffort = "low";
                      textVerbosity = "low";
                      thinking.type = "disabled";
                      temperature = 0.4;
                      clear_thinking = false;
                    };
                  };
                };
                "glm-4.7-flash" = {
                  name = "GLM-4.7 Flash";
                };
              };
            };

            google = {
              npm = "@ai-sdk/google";
              models = {
                "antigravity-gemini-3.1-pro" = {
                  name = "Gemini 3.1 Pro (Antigravity)";
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                  variants = {
                    low = {
                      thinkingLevel = "low";
                    };
                    high = {
                      thinkingLevel = "high";
                    };
                  };
                };
                "antigravity-gemini-3-pro" = {
                  name = "Gemini 3 Pro (Antigravity)";
                  limit = {
                    context = 1048576;
                    output = 65535;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                  variants = {
                    low = {
                      thinkingLevel = "low";
                    };
                    high = {
                      thinkingLevel = "high";
                    };
                  };
                };
                "antigravity-gemini-3-flash" = {
                  name = "Gemini 3 Flash (Antigravity)";
                  limit = {
                    context = 1048576;
                    output = 65536;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                  variants = {
                    minimal = {
                      thinkingLevel = "minimal";
                    };
                    low = {
                      thinkingLevel = "low";
                    };
                    medium = {
                      thinkingLevel = "medium";
                    };
                    high = {
                      thinkingLevel = "high";
                    };
                  };
                };
                "antigravity-claude-sonnet-4-6" = {
                  name = "Claude Sonnet 4.6 (Antigravity)";
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                };
                "antigravity-claude-sonnet-4-6-thinking" = {
                  name = "Claude Sonnet 4.6 Thinking (Antigravity)";
                  limit = {
                    context = 200000;
                    output = 64000;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                  variants = {
                    low = {
                      thinkingConfig = {
                        thinkingBudget = 8192;
                      };
                    };
                    max = {
                      thinkingConfig = {
                        thinkingBudget = 32768;
                      };
                    };
                  };
                };
                "antigravity-claude-opus-4-5-thinking" = {
                  name = "Claude Opus 4.5 Thinking (Antigravity)";
                  limit = {
                    context = 200000;
                    output = 64000;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                  variants = {
                    low = {
                      thinkingConfig = {
                        thinkingBudget = 8192;
                      };
                    };
                    max = {
                      thinkingConfig = {
                        thinkingBudget = 32768;
                      };
                    };
                  };
                };
                "antigravity-claude-opus-4-6-thinking" = {
                  name = "Claude Opus 4.6 Thinking (Antigravity)";
                  limit = {
                    context = 200000;
                    output = 64000;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                  variants = {
                    low = {
                      thinkingConfig = {
                        thinkingBudget = 8192;
                      };
                    };
                    max = {
                      thinkingConfig = {
                        thinkingBudget = 32768;
                      };
                    };
                  };
                };
                "gemini-2.5-flash" = {
                  name = "Gemini 2.5 Flash (Gemini CLI)";
                  limit = {
                    context = 1048576;
                    output = 65536;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                };
                "gemini-2.5-pro" = {
                  name = "Gemini 2.5 Pro (Gemini CLI)";
                  limit = {
                    context = 1048576;
                    output = 65536;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                };
                "gemini-3-flash-preview" = {
                  name = "Gemini 3 Flash Preview (Gemini CLI)";
                  limit = {
                    context = 1048576;
                    output = 65536;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                };
                "gemini-3.1-pro-preview" = {
                  name = "Gemini 3.1 Pro Preview (Gemini CLI)";
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                };
                "gemini-3-pro-preview" = {
                  name = "Gemini 3 Pro Preview (Gemini CLI)";
                  limit = {
                    context = 1048576;
                    output = 65535;
                  };
                  modalities = {
                    input = [
                      "text"
                      "image"
                      "pdf"
                    ];
                    output = [ "text" ];
                  };
                };
              };
            };
          };

          # ── Plugins (from plugins.nix) ─────────────────────────────────
          plugin = [
            "opencode-antigravity-auth@1.5.5"
            "oh-my-opencode@3.7.3"
            "openslimedit@latest"
            "@tarquinen/opencode-dcp@2.1.5"
            "@howaboua/opencode-usage-plugin"
          ];
        };

        # ── Oh-My-OpenCode settings (from plugins.nix) ────────────────
        jvf.programs.opencode.ohMyOpenCodeSettings = {
          disabled_commands = [ ];
          agents = {
            sisyphus = {
              model = "kimi-for-coding/k2p5";
              permission = {
                skill = {
                  "*" = {
                    "*" = "allow";
                  };
                };
              };
            };
            hephaestus = {
              model = "github-copilot/gpt-5.2-codex";
              variant = "medium";
            };
            librarian = {
              model = "minimax/MiniMax-M2.5";
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "research-tools" = "allow";
                  };
                };
              };
            };
            explore = {
              model = "openrouter/stepfun/step-3.5-flash";
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "research-tools" = "allow";
                  };
                };
              };
            };
            atlas = {
              model = "kimi-for-coding/k2p5";
              temperature = 1.0;
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "research-tools" = "allow";
                  };
                };
              };
            };
            prometheus = {
              model = "github-copilot/gpt-5.2";
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "research-tools" = "allow";
                  };
                };
              };
            };
            metis = {
              model = "github-copilot/gemini-3-pro-preview";
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "research-tools" = "allow";
                  };
                };
              };
            };
            momus = {
              model = "kimi-for-coding/k2p5";
              temperature = 1.0;
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "research-tools" = "allow";
                  };
                };
              };
            };
            oracle = {
              model = "github-copilot/gpt-5.2";
            };
            frontend-ui-ux-engineer = {
              model = "minimax/MiniMax-M2.5";
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "vision-tools" = "allow";
                    "browser-debug-tools" = "allow";
                  };
                };
              };
            };
            document-writer = {
              model = "kimi-for-coding/kimi-k2-thinking";
              temperature = 1.0;
            };
            multimodal-looker = {
              model = "github-copilot/gemini-3-flash-preview";
              permission = {
                skill = {
                  "*" = {
                    "*" = "deny";
                    "vision-tools" = "allow";
                  };
                };
              };
            };
          };
          experimental = {
            auto_resume = true;
            dcp_for_compaction = true;
            dynamic_context_pruning = {
              enabled = true;
            };
          };
          ralph_loop = {
            enabled = true;
            default_max_iterations = 1000;
          };
          disabled_hooks = [
            "rules-injector"
          ];
          claude_code = {
            mcp = false;
            commands = false;
            skills = false;
            agents = false;
            hooks = true;
          };
          google_auth = false;
          categories = {
            visual-engineering = {
              model = "github-copilot/gemini-3-flash-preview";
            };
            ultrabrain = {
              model = "github-copilot/gpt-5.2";
            };
            artistry = {
              model = "github-copilot/gemini-3-pro-preview";
            };
            quick = {
              model = "zai-coding-plan/glm-5";
              variant = "fast";
            };
            most-capable = {
              model = "github-copilot/claude-opus-4.6";
            };
            writing = {
              model = "kimi-for-coding/kimi-k2-thinking";
            };
            business-logic = {
              model = "github-copilot/gemini-3-flash-preview";
            };
            general = {
              model = "kimi-for-coding/k2p5";
            };
          };
        };

        # ── Commands (from plugins.nix) ────────────────────────────────
        jvf.programs.opencode.commands.mystatus = lib.mkDefault {
          name = "mystatus";
          agent = "general";
          description = "Query quota usage for all AI accounts";
          prompt = "Use the `mystatus` tool to query quota usage. Return the result as-is without modification.";
        };

        # ── Wrappers config ───────────────────────────────────────────
        jvf.wrappers.users.${cfg.username}.programs.opencode = {
          preserveFiles = [
            "antigravity-accounts.json"
            "node_modules"
            "dcp.jsonc"
            "package.json"
            "bun.lock"
          ];
          packages = [
            pkgs.bun
          ]
          ++ lib.optional isDarwin shellScriptBinDarwin
          ++ lib.optional (!isDarwin) shellScriptBinLinux;
          configs = lib.mkMerge [
            (inputs.lib.aiTools.mkOpencodeMdConfigs config.jvf.aiTools.mcp "agent" cfg.agents)
            (inputs.lib.aiTools.mkOpencodeMdConfigs config.jvf.aiTools.mcp "command" cfg.commands)
            (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
            {
              "AGENTS.md" = cfg.baseRules;
              "opencode.json" = cfg.settings;
              "oh-my-opencode.json" = cfg.ohMyOpenCodeSettings;
              "antigravity.json" = {
                account_selection_strategy = "round-robin";
                switch_on_first_rate_limit = true;
                pid_offset_enabled = true;
              };
              "toolbox.jsonc" = {
                mcp = cfg.mcps;
              };
              "toolbox.json" = {
                mcp = cfg.mcps;
              };
            }
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-opencode = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-opencode = mkConfig { isDarwin = true; };
}
