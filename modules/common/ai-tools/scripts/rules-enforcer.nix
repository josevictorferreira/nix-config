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

      # Model to use for OpenRouter API requests (can be changed by user)
      MODEL="${model}"

      # Get the user prompt from the first argument
      USER_PROMPT="''${1:-}"

      if [[ -z "$USER_PROMPT" ]]; then
        echo "Error: No prompt provided" >&2
        exit 1
      fi

      # Get the current working directory
      CURRENT_PATH="$(pwd)"

      # Find and read all markdown files in .docs/rules/
      PROJECT_RULES=""

      # Check for .docs/rules.md
      if [[ -f "$CURRENT_PATH/.docs/rules.md" ]]; then
        PROJECT_RULES="''${PROJECT_RULES}$(cat "$CURRENT_PATH/.docs/rules.md")"
        PROJECT_RULES="''${PROJECT_RULES}"$'\n\n'
      fi

      # Check for .docs/rules/ directory and read all .md files
      if [[ -d "$CURRENT_PATH/.docs/rules" ]]; then
        while IFS= read -r -d ''' file; do
          if [[ "$file" == *.md ]]; then
            PROJECT_RULES="''${PROJECT_RULES}"$'\n\n---\n\n'
            PROJECT_RULES="''${PROJECT_RULES}$(cat "$file")"
          fi
        done < <(find "$CURRENT_PATH/.docs/rules" -type f -name "*.md" -print0)
      fi

      # Make the OpenRouter API request
      curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY_CODE_AGENT" \
        -H "HTTP-Referer: $CURRENT_PATH" \
        -d "{
          \"model\": \"$MODEL\",
          \"messages\": [
            {
              \"role\": \"system\",
              \"content\": \"Given the following rules and the user prompt, return the text of all rules that may be useful for executing what the user asked. Be concise and only include relevant rules.\"
            },
            {
              \"role\": \"user\",
              \"content\": \"Rules:\n''${PROJECT_RULES}\n\nUser Prompt:\n''${USER_PROMPT}\"
            }
          ]
        }" | jq -r '.choices[0].message.content'
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

