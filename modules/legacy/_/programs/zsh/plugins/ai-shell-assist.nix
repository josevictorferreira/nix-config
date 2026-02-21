{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "zsh-ai-shell-assist";
  src = pkgs.writeTextDir "zsh-ai-shell-assist.plugin.zsh" ''
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

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
