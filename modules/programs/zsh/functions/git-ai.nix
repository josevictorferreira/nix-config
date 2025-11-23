{ lib
, pkgs
, config
, ...
}:

let
  # Core scripts
  git-commit-message = pkgs.writeShellApplication {
    name = "git-commit-message";
    runtimeInputs = [
      pkgs.jq
      pkgs.curl
      pkgs.git
    ];
    text = ''
      # Utility: Trim string to max characters
      trim_string() {
        local input="$1"
        local max_chars="$2"
        if (( ''${#input} > max_chars )); then
          echo "''${input:0:max_chars}...[TRUNCATED]"
        else
          echo "$input"
        fi
      }

      MODEL_NAME="google/gemini-2.5-flash-lite"
      MAX_CHARS=7200000
      LOG_FILE="/tmp/git_commit_message.log"

      # Ensure requirements
      if ! command -v jq >/dev/null || ! command -v curl >/dev/null; then
        echo "[ERROR] jq and curl are required." >&2
        exit 1
      fi

      if ! git rev-parse --git-dir > /dev/null 2>&1; then
        [[ "$DEBUG" == true ]] && echo "[ERROR] Not a git repository." >> "$LOG_FILE"
        exit 1
      fi

      STAGED_CHANGES=$(git diff --cached --no-ext-diff --unified=0)

      if [[ -z "$STAGED_CHANGES" ]]; then
        [[ "$DEBUG" == true ]] && echo "[ERROR] No staged changes." >> "$LOG_FILE"
        exit 1
      fi

      README_CONTENT=""
      if [[ -f "README.md" ]]; then
        README_CONTENT=$(cat README.md)
      fi

      RECENT_COMMITS=""
      if git rev-parse HEAD > /dev/null 2>&1; then
        RECENT_COMMITS=$(git log -n 3 --pretty=format:"%h %s" 2>/dev/null)
      fi

      # Construct Prompt
      COMMIT_MODEL_BASE_PROMPT="You are to act as the author of a commit message in git.

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

      Add a short description of WHY the changes are done after the commit message. Don't start it with \"This commit\", just describe the changes.
      Use the present tense. Title must not be longer than 48 characters. Message must not be longer than 74 characters. Use english for the commit message."

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

      [[ "$DEBUG" == true ]] && {
        echo "[INFO] MODEL: $MODEL_NAME" >> "$LOG_FILE"
        echo "[INFO] PROMPT: $PROMPT" >> "$LOG_FILE"
      }

      PROMPT_TRUNCATED=$(trim_string "$PROMPT" "$MAX_CHARS")

      # Prepare JSON payload
      PAYLOAD=$(jq -n \
        --arg model "$MODEL_NAME" \
        --arg content "$PROMPT_TRUNCATED" \
        '{model: $model, messages: [{role:"user", content: $content}]}')

      RESPONSE=$(curl -sS -w "%{http_code}" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY_COMMIT" \
        -H "Content-Type: application/json" \
        -X POST https://openrouter.ai/api/v1/chat/completions \
        --data-binary "$PAYLOAD" 2>&1)

      HTTP_STATUS="''${RESPONSE: -3}"
      RESPONSE_BODY="''${RESPONSE%???}"

      [[ "$DEBUG" == true ]] && {
        echo "[INFO] HTTP Status: $HTTP_STATUS" >> "$LOG_FILE"
        echo "[INFO] Response: $RESPONSE_BODY" >> "$LOG_FILE"
      }

      COMMIT_MESSAGE=$(printf '%s' "$RESPONSE_BODY" | \
        jq -r '.choices[0].message.content' 2>/dev/null)

      echo "$COMMIT_MESSAGE"
    '';
  };

  ai-cmd-core = pkgs.writeShellApplication {
    name = "ai-cmd-core";
    runtimeInputs = [
      pkgs.jq
      pkgs.curl
      pkgs.fzf
    ];
    text = ''
      # AI Command Suggestion Core Logic

      # Check requirements
      MISSING=()
      command -v curl >/dev/null 2>&1 || MISSING+=(curl)
      command -v jq   >/dev/null 2>&1 || MISSING+=(jq)
      command -v fzf  >/dev/null 2>&1 || MISSING+=(fzf)
      if [ ''${#MISSING[@]} -gt 0 ]; then
        printf 'Missing dependencies: %s\n' "''${MISSING[*]}" >&2
        exit 1
      fi
      if [ -z "$OPENROUTER_API_KEY_TERMINAL" ]; then
        printf 'OPENROUTER_API_KEY_TERMINAL is not set.\n' >&2
        exit 1
      fi

      MODEL_NAME="openai/gpt-4.1-nano"
      BASE_PROMPT=$'Role and Goal: You are a Linux OS command line expert. Output exact Linux commands without explanatory text.\n\nConstraints: Output only syntactically correct Linux commands.\n\nGuidelines: Provide direct, efficient command solutions for file management, system administration, networking, and software management.\n\nClarification: Fill in missing details with sensible defaults.\n\nOUTPUT FORMAT RULES:\n- Return ONLY Linux commands, one per line\n- Provide 3-8 candidate commands\n- No markdown, code fences, bullets, numbering, or comments\n- Order by probability of correctness'

      USER_PROMPT="$*"
      MERGED=$(printf '%s\n\nUser request:\n%s' "$BASE_PROMPT" "$USER_PROMPT")

      PAYLOAD=$(jq -nc \
        --arg model "$MODEL_NAME" \
        --arg content "$MERGED" \
        '{model:$model, messages:[{role:"user", content:$content}], temperature: 0}')

      RESPONSE=$(curl -sS -w "%{http_code}" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY_TERMINAL" \
        -H "Content-Type: application/json" \
        -X POST https://openrouter.ai/api/v1/chat/completions \
        --data-binary "$PAYLOAD" 2>&1)

      HTTP_STATUS="''${RESPONSE: -3}"
      RESPONSE_BODY="''${RESPONSE%???}"

      LIST=$(printf '%s' "$RESPONSE_BODY" | \
        jq -r '.choices[0].message.content' 2>/dev/null)

      if [ -z "$LIST" ]; then
        printf 'The model returned no commands.\n' >&2
        exit 1
      fi

      # Interactive selection with FZF
      CHOICE=$(printf '%s\n' "$LIST" | \
        fzf --prompt="Pick command > " \
          --height=40% --border --ansi)

      if [ $? -eq 0 ]; then
        printf '%s' "$CHOICE"
      else
        exit 1
      fi
    '';
  };

  # Wrappers
  gai = pkgs.writeShellApplication {
    name = "gai";
    runtimeInputs = [
      pkgs.git
      git-commit-message
    ];
    text = ''
      # Git commit with AI-generated message
      # Usage: gai
      # Requires git-commit-message script in PATH

      MSG=$(git-commit-message)
      EXIT_CODE=$?

      if [ $EXIT_CODE -ne 0 ]; then
        echo "[ERROR] Failed to generate commit message." >&2
        exit 1
      fi

      if [[ -z "$MSG" ]]; then
        echo "[ERROR] Empty commit message." >&2
        exit 1
      fi

      git commit -F - <<< "$MSG"
    '';
  };

  gaim = pkgs.writeShellApplication {
    name = "gaim";
    runtimeInputs = [
      pkgs.git
      git-commit-message
    ];
    text = ''
      # Git commit with AI-generated message (editable)
      # Usage: gaim
      # Requires git-commit-message script in PATH

      MSG=$(git-commit-message)
      EXIT_CODE=$?

      if [ $EXIT_CODE -ne 0 ]; then
        echo "[ERROR] Failed to generate commit message." >&2
        exit 1
      fi

      if [[ -z "$MSG" ]]; then
        echo "[ERROR] Empty commit message." >&2
        exit 1
      fi

      git commit --edit -m "$MSG"
    '';
  };

in
{
  commitPackages = [
    git-commit-message
    gai
    gaim
  ];
  commandPackages = [ ai-cmd-core ];

  commitShellInit = "";

  commandShellInit = ''
     # AI command widget for zsh
    function aicmd() {
      local prefix="''${LBUFFER}"
      local choice
      choice=$(ai-cmd-core "$prefix") || return

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
