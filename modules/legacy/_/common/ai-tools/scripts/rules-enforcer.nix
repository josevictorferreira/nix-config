{ lib
, config
, pkgs
, username
, ...
}:

let
  cfg = config.jvf.aiTools.scripts."rules-enforcer";
  model = "openai/gpt-oss-120b";
  scriptPkg = pkgs.writeShellApplication {
    name = "rules-enforcer";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      #!/bin/bash
      set -euo pipefail

      # DEBUG mode - set to "true" to enable verbose logging
      DEBUG="''${DEBUG:-false}"

      # Model to use for OpenRouter API requests (can be changed by user)
      MODEL="${model}"

      # Read the JSON input from stdin
      INPUT_JSON=$(cat)

      if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] INPUT_JSON received: $INPUT_JSON" >&2
      fi

      # Extract the prompt from the JSON input
      USER_PROMPT=$(echo "$INPUT_JSON" | jq -r '.prompt // empty')

      if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] USER_PROMPT extracted: ''${USER_PROMPT:0:100}..." >&2
      fi

      if [[ -z "$USER_PROMPT" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] No prompt found in JSON, returning input." >&2
        fi
        echo "$INPUT_JSON"
        exit 0
      fi

      # Get the current working directory
      CURRENT_PATH="$(pwd)"

      if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] CURRENT_PATH: $CURRENT_PATH" >&2
      fi

      # Find and read all markdown files in .docs/rules/
      PROJECT_RULES=""

      # Check for .docs/rules.md
      if [[ -f "$CURRENT_PATH/.docs/rules.md" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] Found .docs/rules.md, reading content..." >&2
        fi
        PROJECT_RULES="''${PROJECT_RULES}$(cat "$CURRENT_PATH/.docs/rules.md")"
        PROJECT_RULES="''${PROJECT_RULES}"$'\n\n'
      else
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] .docs/rules.md not found" >&2
        fi
      fi

      # Check for .docs/rules/ directory and read all .md files
      if [[ -d "$CURRENT_PATH/.docs/rules" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] Found .docs/rules/ directory, scanning for .md files..." >&2
        fi
        while IFS= read -r -d '''''' file; do
          if [[ "$file" == *.md ]]; then
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] Reading file: $file" >&2
            fi
            PROJECT_RULES="''${PROJECT_RULES}"$'\n\n---\n\n'
            PROJECT_RULES="''${PROJECT_RULES}$(cat "$file")"
          fi
        done < <(find "$CURRENT_PATH/.docs/rules" -type f -name "*.md" -print0)
      else
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] .docs/rules/ directory not found" >&2
        fi
      fi

      if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] PROJECT_RULES length: ''${#PROJECT_RULES} characters" >&2
        echo "[DEBUG] PROJECT_RULES preview:" >&2
        echo "---BEGIN---" >&2
        echo "''${PROJECT_RULES:0:500}" >&2
        echo "---END---" >&2
      fi

      # Exit quietly if no rules found
      if [[ -z "''${PROJECT_RULES//[[:space:]]/}" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] No rules found, returning input." >&2
        fi
        echo "$INPUT_JSON"
        exit 0
      fi

      # Build the user message content with proper escaping
      USER_CONTENT="Rules:\n''${PROJECT_RULES}\n\nUser Prompt:\n''${USER_PROMPT}"

      if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] USER_CONTENT length: ''${#USER_CONTENT} characters" >&2
      fi

      # Make the OpenRouter API request using jq for proper JSON escaping
      JSON_BODY=$(echo '{}' | jq -n --arg model "$MODEL" --arg system_content "Given the following rules and the user prompt, return the text of all rules that may be useful for executing what the user asked. Be concise and only include relevant rules." --arg user_content "$USER_CONTENT" '{model:$model,messages:[{role:"system",content:$system_content},{role:"user",content:$user_content}]}')
      
      # Check for API key
      if [[ -z "''${OPENROUTER_API_KEY_CODE_AGENT:-}" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
          echo "[DEBUG] OPENROUTER_API_KEY_CODE_AGENT not set, returning input." >&2
        fi
        echo "$INPUT_JSON"
        exit 0
      fi

      API_RESPONSE=$(echo "$JSON_BODY" | curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" -H "Content-Type: application/json" -H "Authorization: Bearer $OPENROUTER_API_KEY_CODE_AGENT" -H "HTTP-Referer: $CURRENT_PATH" --data-binary @-)

      if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] API_RESPONSE received: ''${API_RESPONSE:0:200}..." >&2
      fi

      # Extract rules output
      RULES_OUTPUT=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content // empty')

      if [[ -n "$RULES_OUTPUT" ]]; then
        # Append rules to prompt and return full JSON
        NEW_PROMPT="''${USER_PROMPT}"$'\n\n'"Rules to follow:"$'\n'"''${RULES_OUTPUT}"
        echo "$INPUT_JSON" | jq --arg new_prompt "$NEW_PROMPT" '.prompt = $new_prompt'
      else
        # Return original input if no output from API
        echo "$INPUT_JSON"
      fi
    '';
  };
in
{
  options.jvf.aiTools.scripts."rules-enforcer" = {
    enable = (lib.mkEnableOption "Enable rules enforcer") // {
      default = true;
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = scriptPkg;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.username}".packages = [ cfg.package ];
  };
}
