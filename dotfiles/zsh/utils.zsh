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

function conn() {
	local selection=$(cat <<EOF | fzf --prompt="Choose a machine: "
PVE 1     -> root@10.10.10.200
PVE 2     -> root@10.10.10.201
PVE 3     -> root@10.10.10.202
PVE 9(Pi) -> josevictor@10.10.10.209
VM 100    -> josevictor@10.10.10.210
VM 101    -> josevictor@10.10.10.211
VM 200    -> josevictor@10.10.10.220
VM 201    -> josevictor@10.10.10.221
VM 202    -> josevictor@10.10.10.222
VM 300    -> josevictor@10.10.10.230
VM 301    -> josevictor@10.10.10.231
EOF
)
	# Exist if nothing selected
	[[ -z "$selection" ]] && return

	# Extract the user and IP
	local ssh_target=$(echo "$selection" | awk -F'->' '{print $2}' | xargs)
	ssh "$ssh_target"
}
