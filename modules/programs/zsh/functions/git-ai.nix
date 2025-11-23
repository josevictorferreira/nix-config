{
  lib,
  pkgs,
  config,
  ...
}:

let
  commitModelBasePrompt = ''
    You are to act as the author of a commit message in git.

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
    - ♻️ Migrate from `yarn` to `pnpm`
    - ♻️ Move website to Next.js ([#368](https://github.com/carloscuesta/gitmoji/pull/368))
    - 🔧 Bump Node.js to `18`
    - 🏗️ Transform project into a monorepo ([#1235](https://github.com/carloscuesta/gitmoji/pull/1235))
    - 🚚 Extract `gitmojis` as an isolated package
    - 👷 Use `turbo` in `ci` workflow
    - ➕ Install `turbo`
    - 📝 Update contributing guide
    - 🎨 Update readme
    - 🚚 Move `public` folder to `website` package
    - 📝 Add readme file for `gitmojis` package
    - ♻️ Migrate yarn from `classic` to `berry`
    - 📄 Update `LICENSE`
    - ✏️ Fix typo in README ([#1616](https://github.com/carloscuesta/gitmoji/pull/1616))

    Add a short description of WHY the changes are done after the commit message. Don't start it with "This commit", just describe the changes.
    Use the present tense. Title must not be longer than 48 characters. Message must not be longer than 74 characters. Use english for the commit message.
  '';
  commitModelPrompt = ''
    ${commitModelBasePrompt}

    ---

    With the project README.md in mind:
    ```
    {README_CONTENT}
    ```

    ---

    This were the last 3 commit messages in the repository:
    ```
    {COMMIT_MESSAGES}
    ```

    ---

    The following changes were made to the repository:
    ```
    {STAGED_CHANGES}
    ```
  '';
in
{
  commitFunctions = ''
        # Utility: Trim string to max characters
        function trim_string() {
          local input="$1"
          local max_chars="$2"
          if (( ''${#input} > max_chars )); then
            echo "''${input:0:max_chars}...[TRUNCATED]"
          else
            echo "$input"
          fi
        }

        # Generate AI-powered commit message
        function git_commit_message() {
          local MODEL_NAME="google/gemini-2.5-flash-lite"
          local MAX_CHARS=7200000
          local BASE_PROMPT=$(cat <<'EOF'
    ${commitModelPrompt}
    EOF
    )
          local log_file="/tmp/git_commit_message.log"

          if ! ${pkgs.git}/bin/git rev-parse --git-dir > /dev/null 2>&1; then
            [[ "$DEBUG" == true ]] && echo "[ERROR] Not a git repository." >> $log_file
            return 1
          fi

          local staged_changes
          staged_changes=$(${pkgs.git}/bin/git diff --cached --no-ext-diff --unified=0)

          if [[ -z "$staged_changes" ]]; then
            [[ "$DEBUG" == true ]] && echo "[ERROR] No staged changes." >> $log_file
            return 1
          fi

          local readme_content=""
          if [[ -f "README.md" ]]; then
            readme_content=$(cat README.md)
          fi

          local recent_commits=""
          if ${pkgs.git}/bin/git rev-parse HEAD > /dev/null 2>&1; then
            recent_commits=$(${pkgs.git}/bin/git log -n 3 --pretty=format:"%h %s" 2>/dev/null)
          fi

          local prompt="''${BASE_PROMPT//\{README_CONTENT\}/''${readme_content//\#/\\#}}"
          prompt="''${prompt//\{STAGED_CHANGES\}/''${staged_changes//\#/\\#}}"
          prompt="''${prompt//\{COMMIT_MESSAGES\}/''${recent_commits//\#/\\#}}"

          [[ "$DEBUG" == true ]] && {
            echo "[INFO] MODEL: $MODEL_NAME" >> $log_file
            echo "[INFO] PROMPT: $prompt" >> $log_file
          }

          local prompt_truncated=$(trim_string "$prompt" "$MAX_CHARS")

          local payload
          payload=$(${pkgs.jq}/bin/jq -n \
            --arg model "$MODEL_NAME" \
            --arg content "$prompt_truncated" \
            '{model: $model, messages: [{role:"user", content: $content}]}')

          local response
          response=$(${pkgs.curl}/bin/curl -sS -w "%{http_code}" \
            -H "Authorization: Bearer $OPENROUTER_API_KEY_COMMIT" \
            -H "Content-Type: application/json" \
            -X POST https://openrouter.ai/api/v1/chat/completions \
            --data-binary "$payload" 2>&1)

          local http_status="''${response: -3}"
          local response_body="''${response%???}"

          [[ "$DEBUG" == true ]] && {
            echo "[INFO] HTTP Status: $http_status" >> $log_file
            echo "[INFO] Response: $response_body" >> $log_file
          }

          local commit_message=$(printf '%s' "$response_body" | \
            ${pkgs.jq}/bin/jq -r '.choices[0].message.content' 2>/dev/null)

          echo "$commit_message"
        }

        # Git commit with AI-generated message
        function gai() {
          local msg
          if ! msg=$(git_commit_message); then
            echo "[ERROR] Failed to generate commit message." >&2
            return 1
          fi
          [[ -z "$msg" ]] && { echo "[ERROR] Empty commit message." >&2; return 1; }

          ${pkgs.git}/bin/git commit -F - <<< "$msg"
        }

        # Git commit with AI-generated message (editable)
        function gaim() {
          local msg
          msg=$(git_commit_message) || return
          [[ -z "$msg" ]] && { echo "[ERROR] Empty commit message." >&2; return 1; }
          ${pkgs.git}/bin/git commit --edit -m "$msg"
        }
  '';

  commandFunctions = ''
    # Check AI command requirements
    function __ai_cmd_require() {
      local missing=()
      command -v ${pkgs.curl}/bin/curl >/dev/null 2>&1 || missing+=(curl)
      command -v ${pkgs.jq}/bin/jq   >/dev/null 2>&1 || missing+=(jq)
      command -v ${pkgs.fzf}/bin/fzf  >/dev/null 2>&1 || missing+=(fzf)
      if [ ''${#missing[@]} -gt 0 ]; then
        printf 'Missing dependencies: %s\n' "''${missing[*]}" >&2
        return 1
      fi
      if [ -z "$OPENROUTER_API_KEY_TERMINAL" ]; then
        printf 'OPENROUTER_API_KEY_TERMINAL is not set.\n' >&2
        return 1
      fi
    }

    # AI command suggestion core
    function __ai_cmd_core() {
      __ai_cmd_require || return 1

      local MODEL_NAME="openai/gpt-4.1-nano"
      local BASE_PROMPT=$'Role and Goal: You are a Linux OS command line expert. Output exact Linux commands without explanatory text.\n\nConstraints: Output only syntactically correct Linux commands.\n\nGuidelines: Provide direct, efficient command solutions for file management, system administration, networking, and software management.\n\nClarification: Fill in missing details with sensible defaults.\n\nOUTPUT FORMAT RULES:\n- Return ONLY Linux commands, one per line\n- Provide 3-8 candidate commands\n- No markdown, code fences, bullets, numbering, or comments\n- Order by probability of correctness'

      local user_prompt="$*"
      local merged
      merged=$(printf '%s\n\nUser request:\n%s' "$BASE_PROMPT" "$user_prompt")

      local payload
      payload=$(${pkgs.jq}/bin/jq -nc \
        --arg model "$MODEL_NAME" \
        --arg content "$merged" \
        '{model:$model, messages:[{role:"user", content:$content}], temperature: 0}')

      local response
      response=$(${pkgs.curl}/bin/curl -sS -w "%{http_code}" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY_TERMINAL" \
        -H "Content-Type: application/json" \
        -X POST https://openrouter.ai/api/v1/chat/completions \
        --data-binary "$payload" 2>&1)

      local http_status="''${response: -3}"
      local response_body="''${response%???}"

      local list=$(printf '%s' "$response_body" | \
        ${pkgs.jq}/bin/jq -r '.choices[0].message.content' 2>/dev/null)

      if [ -z "$list" ]; then
        printf 'The model returned no commands.\n' >&2
        return 1
      fi

      local choice
      choice=$(printf '%s\n' "$list" | \
        ${pkgs.fzf}/bin/fzf --prompt="Pick command > " \
          --height=40% --border --ansi) || return 1

      printf '%s' "$choice"
    }

    # AI command widget for zsh
    function aicmd() {
      local prefix="''${LBUFFER}"
      local choice
      choice=$(__ai_cmd_core "$prefix") || return

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
}
