# shell-init/environment.nix - Environment variable setup for ZSH
{
  config,
  lib,
  ...
}:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellInit = lib.mkIf cfg.setAsDefaultShell ''
    # PATH Configuration
    export PATH="$HOME/.cargo/bin:$PATH"
    export PATH="$HOME/go/bin:$PATH"
    export PATH="$HOME/.opencode/bin:$PATH"
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="/usr/local/bin:$PATH"
    export PATH="/usr/local/sbin:$PATH"
    export PATH="/usr/sbin:$PATH"
    export PATH="/sbin:$PATH"

    # Environment Variables
    export CLAUDE_CODE_DEBUG=1
    export BAT_THEME="Dracula"
    export EDITOR="nvim"
    export VISUAL="nvim"
    export BROWSER="chromium"
    export SOPS_AGE_KEY_FILE="/var/lib/sops-nix/keys.txt"
    export KUBECONFIG="$HOME/.kube/config"
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
    export CARGO_NET_OFFLINE="false"

    # Workspace Paths
    export WORKSPACE_ROOT="${cfg.workspace.root}"
    export WORKSPACE_SHARED="${cfg.workspace.shared}"

    # Project Paths
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: path: ''export ${name}="${path}"'') cfg.workspace.projects
    )}

    # Secrets - only export if secret file exists
    # Secret files use lowercase_snake_case, env vars use UPPERCASE_SNAKE_CASE
    ${lib.concatStringsSep "\n" (
      map (key: ''
        if [ -r /run/secrets/${key} ]; then
          export ${lib.toUpper key}=$(cat /run/secrets/${key})
        fi
      '') cfg.secrets.keys
    )}
  '';
}
