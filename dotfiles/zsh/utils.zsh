## Automatically creates and runs a phoenix livebook container
function run_livebook () {
  docker run -p 8080:8080 --pull always -u $(id -u):$(id -g) -v $(pwd):/data livebook/livebook
}

## Convert a given text string to base64, automatically copies to clipboard
function b64() {
  echo -n "$1" | base64 -w 0 | wl-copy
}

function bb64() {
  echo -n "$1" | base64 -d
}

## Switch kubernetes contexts
function ksc() {
  contexts=$(kubectl config get-contexts -o name)
  selected_context=$(echo "${contexts}" | fzf)

  if [ -n "$selected_context" ]; then
    kubectl config use-context "$selected_context"
  else
    echo "No context selected."
  fi
}

function als() {
  local cmd=$(alias | sed "s/^alias //" | fzf --ansi --height 20 --preview "echo {}" | awk -F'=' '{print $2}' | tr -d "'")
  if [[ -n $cmd ]]; then
    eval "$cmd"
  fi
}

function notes() {
	NOTES_DIR="$HOME/homelabfs/notetaking/"
  emulate -L zsh -o pipefail

  if [[ -z "$NOTES_DIR" || ! -d "$NOTES_DIR" ]]; then
    print -u2 "NOTES_DIR is not set to a readable directory. Current: ${NOTES_DIR:-<unset>}"
    return 1
  fi
  command -v fzf  >/dev/null || { print -u2 "fzf is required (brew install fzf / pacman -S fzf / apt install fzf)"; return 1; }
  command -v nvim >/dev/null || { print -u2 "neovim is required (brew install neovim, etc.)"; return 1; }

  local -a LIST_CMD
  if command -v fd >/dev/null; then
    LIST_CMD=(fd --hidden --follow --absolute-path -t f -e md . "$NOTES_DIR")
  elif command -v rg >/dev/null; then
    LIST_CMD=(rg --hidden -uu -g '**/*.md' -l --no-messages "$NOTES_DIR")
  else
    LIST_CMD=(find "$NOTES_DIR" -type f -name '*.md' -print)
  fi

  local PREVIEW_CMD
  if command -v glow >/dev/null; then
    PREVIEW_CMD='glow --style dark --width 120 {}'
  elif command -v bat >/dev/null; then
    PREVIEW_CMD='bat --style=numbers --color=always --line-range=:500 {}'
  else
    PREVIEW_CMD='sed -n "1,200p" -- {}'
  fi

  local -a picks
  picks=("${(@f)$(
    "${LIST_CMD[@]}" \
      | sort -f \
      | fzf --multi \
            --height=80% \
            --reverse \
            --prompt='notes> ' \
            --preview="$PREVIEW_CMD" \
            --preview-window=right,60%,border \
            --bind='ctrl-a:toggle-all'
  )}")

  (( ${#picks} )) || return 0

  nvim -- "${picks[@]}"
}

function git_commit_message() {
    local MODEL_NAME="openai/gpt-4.1-nano"
    local BASE_PROMPT="With the project README.md in mind: \"{README_CONTENT}\", the following changes were made to the repository: \"{STAGED_CHANGES}\", generate a commit message to the repository as if the coder would commit those changes right now."
		local BASE_PROMPT=$(cat <<EOF

With the project README.md in mind:
\`\`\`
{README_CONTENT}
\`\`\`

And with the directory tree structure is: 
\`\`\`
{DIRECTORY_TREE}
\`\`\`

The following changes were made to the repository:
\`\`\`
{STAGED_CHANGES}
\`\`\`

Generate a commit message to the repository as if the coder would commit those changes right now.
Use the imperative mood in the subject line.
Make sure the commit message is concise and descriptive.
EOF
)
		local log_file="/tmp/git_commit_message.log"
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
				if [[ "$DEBUG" == true ]]; then
					echo "[ERROR] Not a git repository." >> $log_file
				fi
        return 1
    fi
    
    local staged_changes
    staged_changes=$(git diff --cached --no-color)
    
    if [[ -z "$staged_changes" ]]; then
				if [[ "$DEBUG" == true ]]; then
					echo "[ERROR] No staged changes were found." >> $log_file
				fi
        return 1
    fi
    
    local readme_content=""
    if [[ -f "README.md" ]]; then
        readme_content=$(cat README.md)
    fi
    
    local directory_tree
    directory_tree=$(tree)

		local prompt="${BASE_PROMPT//\{README_CONTENT\}/${readme_content//\#/\\#}}"
		prompt="${prompt//\{STAGED_CHANGES\}/${staged_changes//\#/\\#}}"
		prompt="${prompt//\{DIRECTORY_TREE\}/${directory_tree//\#/\\#}}"
    
		if [[ "$DEBUG" == true ]]; then
			echo "[INFO] OPENROUTER_API_KEY: $OPENROUTER_API_KEY" >> $log_file
			echo "[INFO] MODEL_NAME: $MODEL_NAME" >> $log_file
			echo "[INFO] PROMPT: $prompt\n\n" >> $log_file
		fi

		local payload
		payload=$(jq -n \
			--arg model "$MODEL_NAME" \
			--arg content "$prompt" \
			'{model: $model, messages: [{role:"user", content: $content }]}' )
		
		local response
		response=$(curl -sS -w "%{http_code}" \
			-H "Authorization: Bearer $OPENROUTER_API_KEY" \
			-H "Content-Type: application/json" \
			-X POST https://openrouter.ai/api/v1/chat/completions \
			--data-binary "$payload" 2>&1)

		local http_status="${response: -3}"
    local response_body="${response%???}"
    
    if [[ "$DEBUG" == true ]]; then
        echo "[INFO] HTTP Status Code: $http_status" >> $log_file
        echo "[INFO] Raw Response: $response_body" >> $log_file
    fi

		local commit_message=$(printf '%s' "$response_body" | jq -r '.choices[0].message.content' 2>/dev/null)

    echo "$commit_message"
}

gai() {
  local msg
  if ! msg=$(git_commit_message); then
    echo "[ERROR] Failed to generate commit message." >&2
    return 1
  fi
  [[ -z "$msg" ]] && { echo "[ERROR] Empty commit message." >&2; return 1; }

  git commit -F - <<< "$msg"
}

gaim() {
  local msg
  msg=$(git_commit_message) || return
  [[ -z "$msg" ]] && { echo "[ERROR] Empty commit message." >&2; return 1; }
  git commit --edit -m "$msg"
}

