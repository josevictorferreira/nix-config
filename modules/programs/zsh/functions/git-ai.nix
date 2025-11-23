{ lib
, pkgs
, config
, ...
}:

{
  commitFunctionPrompt = '''';
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
    Generate a commit message to the repository as if the coder would commit those changes right now.
    Use imperative mood in the subject line.
    Make sure the commit message is really concise and descriptive, explain why the change was made.
    Avoid the message being too large.

    With the project README.md in mind:
    ```
    {README_CONTENT}
    ```

    The following changes were made to the repository:
    ```
    {STAGED_CHANGES}
    ```
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

          local prompt="''${BASE_PROMPT//\{README_CONTENT\}/''${readme_content//\#/\\#}}"
          prompt="''${prompt//\{STAGED_CHANGES\}/''${staged_changes//\#/\\#}}"

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
