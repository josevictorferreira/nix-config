{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "zsh-git-ai-commit";
  src = pkgs.writeTextDir "zsh-git-ai-commit.plugin.zsh" ''
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
      local MODEL_NAME="google/gemini-2.5-flash-lite"
      local MAX_CHARS=7200000
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
      local COMMIT_MODEL_BASE_PROMPT="You are to act as the author of a commit message in git.

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
      Use the present tense. Title must not be longer than 48 characters. Message must not be longer than 74 characters. Use english for the commit message. Don't put any \`\`\` characters in the output and commit message;  

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

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
