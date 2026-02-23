# Aspect: programs-zsh
# ZSH shell configuration with Oh My Zsh, custom plugins, aliases, completion,
# history, keybindings, and secret key exports via sops.
# Consolidates all legacy modules/programs/zsh/ sub-files and plugins.
{ ... }:
let
  # ── Options ──────────────────────────────────────────────────────────
  mkZshOptions =
    { config, lib, ... }:
    {
      options.jvf.programs.zsh = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for zsh configuration";
        };

        setAsDefaultShell = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set zsh as default shell";
        };

        plugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "git"
            "sudo"
            "kubectl"
            "aws"
            "postgres"
            "podman"
            "helm"
            "gh"
            "fluxcd"
            "docker"
            "docker-compose"
            "rsync"
            "ssh"
            "tmux"
            "vi-mode"
          ];
          description = "List of Oh My Zsh plugins to load";
        };

        workspace = {
          root = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/Workspace";
            description = "Root workspace directory";
          };

          shared = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/Homelab";
            description = "Shared/homelab directory";
          };

          projects = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Project-specific paths";
            example = {
              agrosmart = "~/Workspace/agrosmart";
            };
          };
        };

        secrets = {
          keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "openrouter_api_key_terminal"
              "openrouter_api_key_commit"
              "openrouter_api_key_autocomplete"
              "openrouter_api_key_code_agent"
              "minimax_api_key"
              "context7_api_key"
              "github_token"
              "hugging_face_api_key"
              "civitai_api_key"
              "gemini_api_key"
              "google_generative_ai_api_key"
              "z_ai_api_key"
              "kimi_api_key"
              "grafana_url"
              "grafana_username"
              "grafana_password"
              "grafana_service_account_token"
              "homelab_postgres_username"
              "homelab_postgres_password"
              "valoris_secret_key"
              "matrix_server_url"
              "matrix_server_username"
              "matrix_server_password"
            ];
            description = "List of sops secret keys to expose as env vars";
          };
        };
      };
    };

  # ── Config ───────────────────────────────────────────────────────────
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.zsh;

      # ── Helper: mkPlugin derivation ──────────────────────────────────
      mkPlugin =
        { name, src }:
        pkgs.stdenv.mkDerivation {
          inherit name src;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out
            cp -r * $out
          '';
        };

      # ── External plugins (fetched from GitHub) ───────────────────────
      externalPlugins = [
        (mkPlugin {
          name = "zsh-fast-syntax-highlighting";
          src = pkgs.fetchFromGitHub {
            owner = "zdharma-continuum";
            repo = "fast-syntax-highlighting";
            rev = "v1.55";
            sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
          };
        })
        (mkPlugin {
          name = "zsh-autosuggestions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "v0.7.0";
            sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
          };
        })
        (mkPlugin {
          name = "zsh-completions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-completions";
            rev = "0.35.0";
            sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg=";
          };
        })
        (mkPlugin {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "v1.1.2";
            sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
          };
        })
        (mkPlugin {
          name = "zsh-history-substring-search";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-history-substring-search";
            rev = "v1.1.0";
            sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
          };
        })
        (mkPlugin {
          name = "zsh-vi-mode";
          src = pkgs.fetchFromGitHub {
            owner = "jeffreytse";
            repo = "zsh-vi-mode";
            rev = "v0.11.0";
            sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
          };
        })
      ];

      # ── Inline plugins (custom shell functions) ──────────────────────
      mkInlinePlugin =
        { name, script }:
        pkgs.stdenv.mkDerivation {
          inherit name;
          src = pkgs.writeTextDir "${name}.plugin.zsh" script;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out
            cp -r $src/* $out/
          '';
        };

      copyCmd = if isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";

      notesDir = "${cfg.workspace.shared}/notetaking";
      fallbackTodo = "${cfg.workspace.shared}/notetaking/checklists/Todo.md";

      inlinePlugins = [
        # ai-shell-assist
        (mkInlinePlugin {
          name = "zsh-ai-shell-assist";
          script = ''
            function _ai_cmd_core() {
              # AI Command Suggestion Core Logic
              local USER_PROMPT="$*"

              # Check requirements
              local MISSING=()
              local OPENROUTER_API_KEY_TERMINAL

              if [ -f /run/secrets/openrouter_api_key_terminal ]; then
                OPENROUTER_API_KEY_TERMINAL=$(cat /run/secrets/openrouter_api_key_terminal)
              else
                printf 'OPENROUTER_API_KEY_TERMINAL is not set (/run/secrets/openrouter_api_key_terminal missing).\n' >&2
                return 1
              fi

              local MODEL_NAME="openai/gpt-4.1-nano"
              local BASE_PROMPT=$'Role and Goal: You are a Linux OS command line expert. Output exact Linux commands without explanatory text.\n\nConstraints: Output only syntactically correct Linux commands.\n\nGuidelines: Provide direct, efficient command solutions for file management, system administration, networking, and software management.\n\nClarification: Fill in missing details with sensible defaults.\n\nOUTPUT FORMAT RULES:\n- Return ONLY Linux commands, one per line\n- Provide 3-8 candidate commands\n- No markdown, code fences, bullets, numbering, or comments\n- Order by probability of correctness'

              local MERGED
              MERGED=$(printf '%s\n\nUser request:\n%s' "$BASE_PROMPT" "$USER_PROMPT")

              local PAYLOAD
              PAYLOAD=$(${pkgs.jq}/bin/jq -nc \
                --arg model "$MODEL_NAME" \
                --arg content "$MERGED" \
                '{model:$model, messages:[{role:"user", content:$content}], temperature: 0}')

              local RESPONSE
              RESPONSE=$(${pkgs.curl}/bin/curl -sS -w "%{http_code}" \
                -H "Authorization: Bearer $OPENROUTER_API_KEY_TERMINAL" \
                -H "Content-Type: application/json" \
                -X POST https://openrouter.ai/api/v1/chat/completions \
                --data-binary "$PAYLOAD" 2>&1)

              local RESPONSE_BODY="''${RESPONSE%???}"

              local LIST
              LIST=$(printf '%s' "$RESPONSE_BODY" | \
                ${pkgs.jq}/bin/jq -r '.choices[0].message.content' 2>/dev/null)

              if [ -z "$LIST" ]; then
                printf 'The model returned no commands.\n' >&2
                return 1
              fi

              # Interactive selection with FZF
              local CHOICE
              CHOICE=$(printf '%s\n' "$LIST" | \
                ${pkgs.fzf}/bin/fzf --prompt="Pick command > " \
                  --height=40% --border --ansi)

              if [[ -n "$CHOICE" ]]; then
                printf '%s' "$CHOICE"
              else
                return 1
              fi
            }

            # AI command widget for zsh
            function aicmd() {
              local prefix="''${LBUFFER}"
              local choice
              choice=$(_ai_cmd_core "$prefix") || return

              if [[ -n $choice ]]; then
                BUFFER="''${choice}"
                CURSOR=''${#BUFFER}
              else
                zle reset-prompt
              fi

              zle redisplay
            }

            zle -N aicmd
          '';
        })

        # als - interactive alias selector
        (mkInlinePlugin {
          name = "zsh-als";
          script = ''
            # Interactive alias selection and execution
            function als() {
              local cmd
              cmd=$(alias | sed "s/^alias //" | \
                ${pkgs.fzf}/bin/fzf --ansi --height 20 \
                  --preview "echo {}" | \
                ${pkgs.gawk}/bin/awk -F'=' '{print $2}' | tr -d "'")
              if [[ -n $cmd ]]; then
                eval "$cmd"
              fi
            }
          '';
        })

        # base64 encode/decode with clipboard (platform-aware)
        (mkInlinePlugin {
          name = "zsh-base64";
          script = ''
            function b64() {
              # Convert text to base64 and copy to clipboard
              if [ -z "$1" ]; then
                echo "Usage: b64 <text>" >&2
                return 1
              fi
              echo -n "$1" | ${pkgs.coreutils}/bin/base64 -w 0 | ${copyCmd}
            }

            function bb64() {
              # Decode base64
              if [ -z "$1" ]; then
                echo "Usage: bb64 <base64_string>" >&2
                return 1
              fi
              echo -n "$1" | ${pkgs.coreutils}/bin/base64 -d
            }
          '';
        })

        # git-ai-commit
        (mkInlinePlugin {
          name = "zsh-git-ai-commit";
          script =
            let
              model = "google/gemini-2.5-flash-lite";
              maxCharacters = "2100000";
              prompt = ''
                # GIT COMMIT MESSAGE

                You need to act as a developer author of a commit message in git.

                Your mission is to create clean and comprehensive commit messages as per the GitMoji specification and explain WHAT were the changes and mainly WHY the changes were done. I'll send you an output of 'git diff --staged' command(this are the most important to define the message), secondly the README.md of the project for base context, and finally the last 3 commit messages made in the repository, and you are responsible to convert it into a commit message. Output only and only the commit message.

                Use GitMoji convention to preface the commit. Here are some help to choose the right emoji (emoji, description):
                - 💄 Add or update the UI and style files.
                - 🎉 Begin a project.
                - ✅ Add, update, or pass tests.
                - 🔒️ Fix security or privacy issues.
                - 🔐 Add or update secrets.
                - 🔖 Release / Version tags.
                - 🚨 Fix compiler / linter warnings.
                - 🚧 Work in progress.
                - 💚 Fix CI Build.
                - ⬇️ Downgrade dependencies.
                - ⬆️ Upgrade dependencies.
                - 📌 Pin dependencies to specific versions.
                - 👷 Add or update CI build system.
                - 📈 Add or update analytics or track code.
                - ♻️ Refactor code.
                - ➕ Add a dependency.
                - ➖ Remove a dependency.
                - 🔧 Add or update configuration files.
                - 🔨 Add or update development scripts.
                - 🌐 Internationalization and localization.
                - ✏️ Fix typos.
                - 💩 Write bad code that needs to be improved.
                - ⏪️ Revert changes.
                - 🔀 Merge branches.
                - 📦️ Add or update compiled files or packages.
                - 👽️ Update code due to external API changes.
                - 🚚 Move or rename resources (e.g.: files, paths, routes).
                - 📄 Add or update license.
                - 💥 Introduce breaking changes.
                - 🍱 Add or update assets.
                - ♿️ Improve accessibility.
                - 💡 Add or update comments in source code.
                - 🍻 Write code drunkenly.
                - 💬 Add or update text and literals.
                - 🗃️ Perform database related changes.
                - 🔊 Add or update logs.
                - 🔇 Remove logs.
                - 👥 Add or update contributor(s).
                - 🚸 Improve user experience / usability.
                - 🏗️ Make architectural changes.
                - 📱 Work on responsive design.
                - 🤡 Mock things.
                - 🥚 Add or update an easter egg.
                - 🙈 Add or update a .gitignore file.
                - 📸 Add or update snapshots.
                - ⚗️ Perform experiments.
                - 🔍️ Improve SEO.
                - 🏷️ Add or update types.
                - 🌱 Add or update seed files.
                - 🚩 Add, update, or remove feature flags.
                - 🥅 Catch errors.
                - 💫 Add or update animations and transitions.
                - 🗑️ Deprecate code that needs to be cleaned up.
                - 🛂 Work on code related to authorization, roles and permissions.
                - 🩹 Simple fix for a non-critical issue.
                - 🧐 Data exploration/inspection.
                - ⚰️ Remove dead code.
                - 🧪 Add a failing test.
                - 👔 Add or update business logic.
                - 🩺 Add or update healthcheck.
                - 🧱 Infrastructure related changes.
                - 🧑‍💻 Improve developer experience.
                - 💸 Add sponsorships or money related infrastructure.
                - 🧵 Add or update code related to multithreading or concurrency.
                - 🦺 Add or update code related to validation.

                Examples:
                - ⬆️ Bump pnpm/action-setup from 3 to 4
                - ♻️ Migrate from \`yarn\` to \`pnpm\`
                - ♻️ Move website to Next.js ([#368](https://github.com/carloscuesta/gitmoji/pull/368))
                - 🔧 Bump Node.js to \`18\`
                - 🏗️ Transform project into a monorepo ([#1235](https://github.com/carloscuesta/gitmoji/pull/1235))
                - 🚚 Extract \`gitmojis\` as an isolated package
                - 👷 Use \`turbo\` in \`ci\` workflow
                - ➕ Install \`turbo\`
                - 📝 Update contributing guide
                - 🎨 Update readme
                - 🚚 Move \`public\` folder to \`website\` package
                - 📝 Add readme file for \`gitmojis\` package
                - ♻️ Migrate yarn from \`classic\` to \`berry\`
                - 📄 Update \`LICENSE\`
                - ✏️ Fix typo in README ([#1616](https://github.com/carloscuesta/gitmoji/pull/1616))

                # RULES
                - Add a short description of WHY the changes are done after the commit message. Don't start it with "This commit", just describe the changes.
                - Use the present tense. Title must not be longer than 48 characters. Message must not be longer than 74 characters. Use english for the commit message.
                - **IMPORTANT** Your output must include only the message string of the commit. No markdown formatting tags or syntax is needed.
                - **IMPORTANT** Never include triple backticks ("\`\`\`"), which are used for Markdown code blocks, in the output formatting.
              '';
            in
            ''
                            # Utility: Trim string to max characters
                            function _trim_string() {
                              local input="$1"
                              local max_chars="$2"
                              if (( ''${#input} > max_chars )); then
                                echo "''${input:0:max_chars}...[TRUNCATED]"
                              else
                                echo "$input"
                              fi
                            }

                            function _generate_commit_message() {
                              local MODEL_NAME="${model}"
                              local MAX_CHARS=${maxCharacters}
                              local OPENROUTER_API_KEY_COMMIT
                              local STAGED_CHANGES
                              local README_CONTENT=""
                              local RECENT_COMMITS=""
                              local PROMPT
                              local PROMPT_TRUNCATED
                              local PAYLOAD
                              local RESPONSE
                              local RESPONSE_BODY
                              local COMMIT_MESSAGE

                              if [ -f /run/secrets/openrouter_api_key_commit ]; then
                                  OPENROUTER_API_KEY_COMMIT=$(cat /run/secrets/openrouter_api_key_commit)
                              else
                                  echo "[ERROR] Secret /run/secrets/openrouter_api_key_commit not found." >&2
                                  return 1
                              fi

                              if ! ${pkgs.git}/bin/git rev-parse --git-dir > /dev/null 2>&1; then
                                return 1
                              fi

                              STAGED_CHANGES=$(${pkgs.git}/bin/git diff --cached --no-ext-diff --unified=0)

                              if [[ -z "$STAGED_CHANGES" ]]; then
                                return 1
                              fi

                              if [[ -f "README.md" ]]; then
                                README_CONTENT=$(cat README.md)
                              fi

                              if ${pkgs.git}/bin/git rev-parse HEAD > /dev/null 2>&1; then
                                RECENT_COMMITS=$(${pkgs.git}/bin/git log -n 3 --pretty=format:"%h %s" 2>/dev/null)
                              fi

                              # Construct Prompt
                              local COMMIT_MODEL_BASE_PROMPT
                    COMMIT_MODEL_BASE_PROMPT=$(cat <<'PROMPT_EOF'
              ${prompt}
              PROMPT_EOF
              )

                              # Replace placeholders locally in bash
                              PROMPT="$COMMIT_MODEL_BASE_PROMPT

                              ---

                              With the project README.md in mind:
                              \`\`\`
                              $README_CONTENT
                              \`\`\`

                              ---

                              This were the last 3 commit messages in the repository:
                              \`\`\`
                              $RECENT_COMMITS
                              \`\`\`

                              ---

                              The following changes were made to the repository:
                              \`\`\`
                              $STAGED_CHANGES
                              \`\`\`
                              "

                              PROMPT_TRUNCATED=$(_trim_string "$PROMPT" "$MAX_CHARS")

                              # Prepare JSON payload
                              PAYLOAD=$(${pkgs.jq}/bin/jq -n \
                                --arg model "$MODEL_NAME" \
                                --arg content "$PROMPT_TRUNCATED" \
                                '{model: $model, messages: [{role:"user", content: $content}]}')

                              RESPONSE=$(${pkgs.curl}/bin/curl -sS -w "%{http_code}" \
                                -H "Authorization: Bearer $OPENROUTER_API_KEY_COMMIT" \
                                -H "Content-Type: application/json" \
                                -X POST https://openrouter.ai/api/v1/chat/completions \
                                --data-binary "$PAYLOAD" 2>&1)

                              RESPONSE_BODY="''${RESPONSE%???}"

                              COMMIT_MESSAGE=$(printf '%s' "$RESPONSE_BODY" | \
                                ${pkgs.jq}/bin/jq -r '.choices[0].message.content' 2>/dev/null)

                              echo "$COMMIT_MESSAGE"
                            }

                            function gai() {
                              local MSG
                              MSG=$(_generate_commit_message)
                              local EXIT_CODE=$?

                              if [ $EXIT_CODE -ne 0 ]; then
                                echo "[ERROR] Failed to generate commit message." >&2
                                return 1
                              fi

                              if [[ -z "$MSG" ]]; then
                                echo "[ERROR] Empty commit message." >&2
                                return 1
                              fi

                              ${pkgs.git}/bin/git commit -F - <<< "$MSG"
                            }

                            function gaim() {
                              local MSG
                              MSG=$(_generate_commit_message)
                              local EXIT_CODE=$?

                              if [ $EXIT_CODE -ne 0 ]; then
                                echo "[ERROR] Failed to generate commit message." >&2
                                return 1
                              fi

                              if [[ -z "$MSG" ]]; then
                                echo "[ERROR] Empty commit message." >&2
                                return 1
                              fi

                              ${pkgs.git}/bin/git commit --edit -m "$MSG"
                            }
            '';
        })

        # kubernetes context switcher
        (mkInlinePlugin {
          name = "zsh-kubernetes";
          script = ''
            function ksc() {
              local contexts selected_context
              contexts=$(${pkgs.kubectl}/bin/kubectl config get-contexts -o name)
              selected_context=$(echo "''${contexts}" | ${pkgs.fzf}/bin/fzf)

              if [ -n "$selected_context" ]; then
                ${pkgs.kubectl}/bin/kubectl config use-context "$selected_context"
              else
                echo "No context selected."
              fi
            }
          '';
        })

        # nix utility functions
        (mkInlinePlugin {
          name = "nix-utils-functions";
          script = ''
            function nr() {
              nix run .#"$@"
            }

            # Initialize from any flake template in ~/.config/nix
            # Usage: flake-init [template-name]
            # Without args, opens fzf to select from available templates
            flake-init() {
              local nix_config="$HOME/.config/nix"
              local template="$1"

              if ! command -v jq >/dev/null 2>&1; then
                echo "Error: jq is required for flake-init" >&2
                return 1
              fi

              if [[ -z "$template" ]]; then
                # fzf mode - list and select templates from the flake
                template=$(nix flake show "path:$nix_config" --json 2>/dev/null \
                  | jq -r '.templates // {} | keys[]' \
                  | fzf --prompt="Select flake template: " --height=40% --reverse)
                [[ -z "$template" ]] && echo "No template selected" && return 1
              fi

              nix flake init -t "path:$nix_config#$template" && \
                echo "Initialized '$template' template. Run 'nix develop --impure' to enter."
            }
          '';
        })

        # notes browser
        (mkInlinePlugin {
          name = "zsh-notes";
          script = ''
            function notes() {
              export NOTES_DIR="${notesDir}"

              if [[ -z "$NOTES_DIR" || ! -d "$NOTES_DIR" ]]; then
                echo "NOTES_DIR not accessible: ''${NOTES_DIR:-<unset>}" >&2
                return 1
              fi

              # Select list command based on availability
              local LIST_CMD
              if command -v ${pkgs.fd}/bin/fd >/dev/null; then
                mapfile -t LIST_CMD < <(${pkgs.fd}/bin/fd --hidden --follow --absolute-path -t f -e md . "$NOTES_DIR")
              elif command -v ${pkgs.ripgrep}/bin/rg >/dev/null; then
                mapfile -t LIST_CMD < <(${pkgs.ripgrep}/bin/rg --hidden -uu -g '**/*.md' -l --no-messages "$NOTES_DIR")
              else
                mapfile -t LIST_CMD < <(${pkgs.findutils}/bin/find "$NOTES_DIR" -type f -name '*.md' -print)
              fi

              # Select preview command
              local PREVIEW_CMD
              if command -v ${pkgs.glow}/bin/glow >/dev/null; then
                PREVIEW_CMD='${pkgs.glow}/bin/glow --style dark --width 120 {}'
              elif command -v ${pkgs.bat}/bin/bat >/dev/null; then
                PREVIEW_CMD='${pkgs.bat}/bin/bat --style=numbers --color=always --line-range=:500 {}'
              else
                PREVIEW_CMD='sed -n "1,200p" -- {}'
              fi

              printf "%s\n" "''${LIST_CMD[@]}" | sort -f | ${pkgs.fzf}/bin/fzf --multi \
                --height=80% \
                --reverse \
                --prompt='notes> ' \
                --preview="$PREVIEW_CMD" \
                --preview-window=right,60%,border \
                --bind='ctrl-a:toggle-all' | \
              xargs -r -d '\n' ${pkgs.neovim}/bin/nvim
            }
          '';
        })

        # run-livebook
        (mkInlinePlugin {
          name = "zsh-run-livebook";
          script = ''
            function run-livebook() {
              # Automatically creates and runs a phoenix livebook container
              ${pkgs.docker}/bin/docker run -p 8080:8080 --pull always \
                -u "$(id -u):$(id -g)" -v "$(pwd):/data" livebook/livebook
            }

            # Legacy alias for backward compatibility
            alias run_livebook="run-livebook"
          '';
        })

        # todo
        (mkInlinePlugin {
          name = "zsh-todo";
          script = ''
            function todo() {
              local fallback_file="${fallbackTodo}"
              local git_root todo_file

              # Try to find git root
              git_root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)

              if [[ -n "$git_root" ]]; then
                # Check for existing TODO.md or .docs/TODO.md
                if [[ -f "$git_root/TODO.md" ]]; then
                  todo_file="$git_root/TODO.md"
                elif [[ -f "$git_root/.docs/TODO.md" ]]; then
                  todo_file="$git_root/.docs/TODO.md"
                else
                  # Create .docs/TODO.md if neither exists
                  ${pkgs.coreutils}/bin/mkdir -p "$git_root/.docs"
                  todo_file="$git_root/.docs/TODO.md"
                  if [[ ! -f "$todo_file" ]]; then
                    echo "# TODO" > "$todo_file"
                    echo "" >> "$todo_file"
                    echo "Created: $(date +%Y-%m-%d)" >> "$todo_file"
                    echo "" >> "$todo_file"
                  fi
                fi
              else
                # Fallback: no git repo found
                todo_file="$fallback_file"
                # Ensure fallback directory exists
                ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$todo_file")"
                if [[ ! -f "$todo_file" ]]; then
                  echo "# TODO" > "$todo_file"
                  echo "" >> "$todo_file"
                  echo "Created: $(date +%Y-%m-%d)" >> "$todo_file"
                  echo "" >> "$todo_file"
                fi
              fi

              ${pkgs.neovim}/bin/nvim "$todo_file"
            }
          '';
        })
      ];

      customPkgs = inlinePlugins ++ externalPlugins;

      # ── Aliases ────────────────────────────────────────────────────────
      workspace = cfg.workspace.root;
      shared = cfg.workspace.shared;
      notetaking = "${shared}/notetaking";

      baseAliases = {
        sudo = "sudo -E ";
        s = "sudo -E ";
        bcat = "bat";
        ls = "eza -a --icons";
        ll = "eza -al --icons";
        lt = "eza -a --tree --level=1 --icons";
        ns = "nix-shell --run zsh";
        nd = "nix develop --command zsh";
        nr = "nix run .#";
      };

      navigationAliases = {
        wspc = "cd ${workspace}";
        shared = "cd ${shared}";
        nixc = "cd $HOME/.config/nix";
      };

      noteAliases = {
        ideas = "nvim ${notetaking}/ideas/Ideas.md";
        prompts = "nvim ${notetaking}/notes/Prompts.md";
        sht = "nvim ${notetaking}/notes/CheatSheets.md";
        sheet = "nvim ${notetaking}/notes/CheatSheets.md";
        plan = "sops --config=${shared}/.sops.yaml ${notetaking}/00-inbox/plan.enc.md";
        gtodo = "nvim ${notetaking}/01-projects/active/Todo.md";
      };

      devAliases = {
        k = "kubectl";
        v = "nvim";
        d = "podman";
        dc = "podman-compose";
        docker-compose = "podman-compose";
        docker = "podman";
        m = "make";
        be = "bundle exec ";
        ber = "bundle exec rspec --fail-fast ";
        uvr = "uv run ";
        uvrp = "uv run pytest ";
        uvrd = "uv run python manage.py ";
        rtmux = "tmux source-file ~/.config/tmux/tmux.conf";
      };

      personalProjectAliases = {
        buy = "nvim ${workspace}/buy.md";
        zshrc = "nvim $HOME/.config/nix/modules/programs/zsh/default.nix";
        aliases = "nvim $HOME/.config/nix/modules/programs/zsh/aliases.nix";
        exer = "cd ${workspace}/exercism";
        readm = "cd ${workspace}/readmore-project";
        ebook = "cd ${workspace}/ebookit";
        ebookit = "cd ${workspace}/ebookit/ebookit-extension";
        rinha = "cd ${workspace}/rinha-backend";
        hl = "cd ${workspace}/homelab";
        val = "cd ${workspace}/valoris";
        valb = "cd ${workspace}/valoris/backend";
        valf = "cd ${workspace}/valoris/frontend";
        vista = "cd ${workspace}/vista-valor";
        real = "cd ${workspace}/realiza-monorepo";
      };

      k8sAliases = {
        prod = "k9s -n production -c pods";
        stag = "k9s -n staging -c pods";
        set_mini = "kubectl config use-context minikube && kubectl config set-context minikube";
      };

      workAliases = {
        agro = "cd ${workspace}/agrosmart";
        nex = "cd ${workspace}/agrosmart/nexus/nexus-backend";
        farm = "cd ${workspace}/agrosmart/booster/farm-service";
        acc = "cd ${workspace}/agrosmart/booster/account-service";
        field = "cd ${workspace}/agrosmart/booster/booster-field-notebook-service";
        sat = "cd ${workspace}/agrosmart/booster/satellite-image-service";
        geo = "cd ${workspace}/agrosmart/booster/georef-measures-service";
        map = "cd ${workspace}/agrosmart/booster/weather-map-service";
        weat = "cd ${workspace}/agrosmart/booster/weather-forecast-service";
        inf = "cd ${workspace}/agrosmart/booster/booster-infra";
        kong = "cd ${workspace}/agrosmart/booster/booster-api-gateway";
        nexapi = "cd ${workspace}/agrosmart/nexus/nexus-api-gateway";
        key = "cd ${workspace}/agrosmart/booster/keycloak";
      };

      lsAliases = ''
        alias ls="eza -a --icons"
        alias ll="eza -al --icons"
        alias lt="eza -a --tree --level=1 --icons"
      '';

      structured =
        baseAliases
        // navigationAliases
        // noteAliases
        // devAliases
        // personalProjectAliases
        // k8sAliases
        // workAliases;

      structuredAliasesScript = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "alias ${name}=${lib.escapeShellArg value}") structured
      );

      # ── Shell init sections ──────────────────────────────────────────
      environmentShellInit = ''
        # XDG Compliance
        export ZDOTDIR=$HOME/.config/zsh
        mkdir -p $ZDOTDIR
        mkdir -p $HOME/.cache/zsh

        # Standard OS variables
        export ZSH_DISABLE_COMPFIX=true
        export EDITOR='nvim'
        export VISUAL='nvim'
        export BROWSER='brave'
        export PODMAN_COLOR=true
        export COLORTERM=truecolor

        # Fix TERM for kitty (may inherit wrong TERM from parent tmux)
        [[ -n "$KITTY_WINDOW_ID" && "$TERM" != "xterm-kitty" ]] && export TERM=xterm-kitty

        # Add local bin and homebrew to path
        export PATH=$HOME/.local/bin:/opt/homebrew/bin:$PATH
      '';

      loginInit = ''
        # Login shell initialization
        export ZSH_DISABLE_COMPFIX=true
      '';

      historyShellInit = ''
        # History configuration
        HISTSIZE=10000
        HISTFILE="$HOME/.cache/zsh/history"
        SAVEHIST=$HISTSIZE
        HISTDUP=erase

        # History options
        setopt appendhistory
        setopt sharehistory
        setopt hist_ignore_space
        setopt hist_ignore_all_dups
        setopt hist_save_no_dups
        setopt hist_ignore_dups
        setopt hist_find_no_dups
      '';

      completionShellInit = ''
        # Completion settings
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

        # FZF tab completion
        zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        zstyle ':fzf-tab:*' popup-min-size 80 12
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1a --color=always $realpath'
      '';

      keybindingsShellInit = ''
        # Vi mode
        bindkey -v
        bindkey -M vicmd 'k' history-substring-search-up
        bindkey -M vicmd 'j' history-substring-search-down

        # History search keybindings
        bindkey '^R' history-incremental-search-backward
        bindkey '^P' history-substring-search-up
        bindkey '^N' history-substring-search-down
        bindkey '^p' history-beginning-search-backward
        bindkey '^n' history-beginning-search-forward

        # Navigation
        bindkey '^[[A' forward-char

        # AI command binding
        bindkey '^G' aicmd

        # FZF history search
        bindkey '^ ' fzf_history_search_prefix_widget

        # Enable cursor blinking (only for interactive terminals)
        [[ -t 1 ]] && print -n '\e[5 q'
      '';

    in
    {
      imports = [ mkZshOptions ];

      config = (
        lib.mkMerge [
          {
            # Assertion test
            assertions = [
              {
                assertion = pkgs ? zsh;
                message = "zsh package must be available";
              }
            ];

            programs.zsh = {
              enable = true;

              interactiveShellInit = lib.concatStringsSep "\n" [
                # Enable Oh My Zsh
                ''
                  export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                  export ZSH_THEME=""
                  plugins=(${lib.concatStringsSep " " cfg.plugins})
                  source $ZSH/oh-my-zsh.sh
                ''

                # Load custom plugins
                (lib.concatStringsSep "\n" (
                  map
                    (pkg: ''
                      # Load ${pkg.name}
                      for script in ${pkg}/*.plugin.zsh ${pkg}/*.zsh; do
                        if [ -f "$script" ]; then
                          source "$script"
                        fi
                      done
                    '')
                    customPkgs
                ))

                # Force ls aliases after OMZ loading
                lsAliases

                # Load all structured aliases (nix-darwin's environment.shellAliases only works for bash)
                structuredAliasesScript
              ];

              shellInit = lib.concatStringsSep "\n" [
                environmentShellInit
                (lib.concatMapStringsSep "\n"
                  (key: ''
                    export ${lib.toUpper key}="$(cat /run/secrets/${key})"
                  '')
                  cfg.secrets.keys)
                historyShellInit
                completionShellInit
                keybindingsShellInit
              ];

              loginShellInit = loginInit;

              enableCompletion = true;
              # Disable nix-darwin's default prompt (prompt suse) - we use starship
              promptInit = "";
            };

            environment.shellAliases = structured;

            users.users.${cfg.username} = {
              shell = pkgs.zsh;
              packages = [
                pkgs.oh-my-zsh
                pkgs.fzf
                pkgs.ripgrep
                pkgs.eza
                pkgs.jq
                pkgs.curl
                pkgs.bat
              ];
            };

            sops.secrets = (
              lib.genAttrs cfg.secrets.keys (key: {
                owner = cfg.username;
                mode = "0400";
              })
            );
          }
          (lib.mkIf cfg.setAsDefaultShell {
            environment.shells = [
              pkgs.zsh
            ];
          })
        ]
      );
    };
in
{
  flake.modules.nixos.programs-zsh = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-zsh = mkConfig { isDarwin = true; };
}
