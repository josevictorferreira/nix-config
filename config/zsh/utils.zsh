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
