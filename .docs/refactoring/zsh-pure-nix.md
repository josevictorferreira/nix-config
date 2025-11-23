# Zsh Pure Nix Refactoring Plan

## Executive Summary

This document outlines a comprehensive plan to refactor the current zsh configuration from mixed `.zsh` files to pure Nix code. The goal is to achieve better maintainability, type safety, declarative configuration, and elimination of runtime file sourcing.

## Current Architecture Analysis

### Current Structure
```
modules/programs/zsh/
├── default.nix          # Module entry point (91 lines)
├── aliases.zsh          # Aliases and workspace variables (79 lines)
├── init.zsh             # Source orchestration (8 lines)
├── plugins.zsh          # Zinit plugin management (87 lines)
├── settings.zsh         # Environment, history, keybindings (44 lines)
├── secrets.zsh          # Secret environment variables (9 lines)
└── utils.zsh            # Shell functions (264 lines)
```

### Problems with Current Approach
1. **Runtime file sourcing**: Files are sourced at shell startup, creating initialization overhead
2. **No type safety**: Shell scripts lack compile-time validation
3. **Difficult to compose**: Hard to override or extend specific parts
4. **Non-declarative**: Imperative shell scripts vs declarative Nix
5. **Zinit complexity**: Plugin manager adds runtime dependency and complexity
6. **Mixed paradigms**: Nix reads files that contain imperative shell code

## Target Architecture

### New Structure
```
modules/programs/zsh/
├── default.nix              # Main module orchestrator
├── aliases.nix              # Structured alias definitions
├── environment.nix          # Environment variables and exports
├── functions/
│   ├── default.nix          # Function registry
│   ├── development.nix      # Dev-related functions (livebook, base64)
│   ├── kubernetes.nix       # K8s context switching
│   ├── navigation.nix       # Notes, alias search
│   └── git-ai.nix           # AI-powered git functions
├── history.nix              # History configuration
├── keybindings.nix          # Key bindings and vi-mode
├── options.nix              # Module options schema
├── plugins.nix              # Plugin declarations (using programs.zsh.plugins)
├── prompt.nix               # Prompt configuration (p10k)
└── completion.nix           # Completion and fzf-tab settings
```

### Design Principles

1. **Single Responsibility**: Each file handles one concern
2. **Composability**: Easy to enable/disable features
3. **Type Safety**: Use Nix types to validate configuration
4. **No Runtime Dependencies**: Eliminate Zinit, use Nix plugin management
5. **Pure Functions**: All shell functions defined in Nix strings
6. **Explicit Dependencies**: Package dependencies declared in module

## Implementation Plan

### Phase 1: Foundation (Core Module System)

#### Step 1.1: Create `options.nix`
Define the module interface with typed options:

```nix
{ lib, ... }:

{
  options.jvf.programs.zsh = {
    enable = lib.mkEnableOption "zsh with advanced features";
    
    username = lib.mkOption {
      type = lib.types.str;
      description = "Username for zsh configuration";
    };
    
    setAsDefaultShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set zsh as default shell";
    };
    
    features = {
      aiCommit = lib.mkEnableOption "AI-powered git commit messages";
      aiCommand = lib.mkEnableOption "AI command suggestions";
      advancedHistory = lib.mkEnableOption "Advanced history search with fzf";
      viMode = lib.mkEnableOption "Vi mode keybindings";
      powerLevel10k = lib.mkEnableOption "PowerLevel10k prompt";
      workAliases = lib.mkEnableOption "Work-specific aliases (Agrosmart)";
    };
    
    workspace = {
      root = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Workspace";
        description = "Root workspace directory";
      };
      
      shared = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Homelab";
        description = "Shared/homelab directory";
      };
      
      projects = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Project-specific paths";
        example = { agrosmart = "~/Workspace/agrosmart"; };
      };
    };
    
    secrets = {
      enable = lib.mkEnableOption "sops-based secret management";
      
      keys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "openrouter_terminal"
          "openrouter_commit"
          "openrouter_autocomplete"
          "openrouter_code_agent"
          "context7_api_key"
          "github_token"
        ];
        description = "List of sops secret keys to expose";
      };
    };
  };
}
```

**Benefits:**
- Type-safe configuration
- Self-documenting options
- Easy feature toggling
- Workspace configuration abstraction

#### Step 1.2: Create `default.nix`
Main orchestrator that imports and composes all modules:

```nix
{ lib, pkgs, config, username, ... }:

let
  cfg = config.jvf.programs.zsh;
  
  # Import all submodules
  options = import ./options.nix { inherit lib; };
  aliases = import ./aliases.nix { inherit lib pkgs config; };
  environment = import ./environment.nix { inherit lib pkgs config; };
  functions = import ./functions { inherit lib pkgs config; };
  history = import ./history.nix { inherit lib pkgs config; };
  keybindings = import ./keybindings.nix { inherit lib pkgs config; };
  plugins = import ./plugins.nix { inherit lib pkgs config; };
  prompt = import ./prompt.nix { inherit lib pkgs config; };
  completion = import ./completion.nix { inherit lib pkgs config; };

in
{
  imports = [ options ];
  
  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      
      # Merge all shell initialization
      shellInit = lib.concatStringsSep "\n" [
        environment.shellInit
        (lib.optionalString cfg.features.powerLevel10k prompt.shellInit)
      ];
      
      # Interactive shell configuration
      interactiveShellInit = lib.concatStringsSep "\n\n" [
        history.config
        completion.config
        keybindings.config
        functions.all
        aliases.config
      ];
      
      # Login shell configuration
      loginShellInit = environment.loginInit;
      
      # Plugin configuration using programs.zsh.plugins
      plugins = plugins.list;
      
      # Shell aliases (structured)
      shellAliases = aliases.structured;
    };
    
    # System-level configuration
    environment = {
      shells = [ pkgs.zsh ];
      variables.ZDOTDIR = "$HOME/.config/zsh";
      systemPackages = [
        pkgs.zsh
        pkgs.fzf
        pkgs.ripgrep
        pkgs.direnv
        pkgs.eza
        pkgs.jq
        pkgs.curl
      ];
    };
    
    # User configuration
    users.users.${cfg.username} = lib.mkIf cfg.setAsDefaultShell {
      shell = pkgs.zsh;
    };
    
    # Secrets configuration (if enabled)
    sops.secrets = lib.mkIf cfg.secrets.enable (
      lib.genAttrs cfg.secrets.keys (key: {
        owner = config.users.users.${cfg.username}.name;
        mode = "0400";
      })
    );
  };
}
```

**Benefits:**
- Clear separation of concerns
- Conditional feature inclusion
- Single source of truth
- No file sourcing at runtime

### Phase 2: Content Migration

#### Step 2.1: Create `aliases.nix`
Transform shell aliases into structured Nix attribute sets:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
  
  # Workspace paths
  workspace = cfg.workspace.root;
  shared = cfg.workspace.shared;
  notetaking = "${shared}/notetaking";
  
  # Base aliases (always available)
  baseAliases = {
    # Sudo
    sudo = "sudo -E ";
    s = "sudo -E ";
    
    # Common tools
    k = "kubectl";
    v = "nvim";
    d = "docker";
    m = "make";
    
    # Better ls
    ls = "eza -a --icons";
    ll = "eza -al --icons";
    lt = "eza -a --tree --level=1 --icons";
    
    # Tmux
    rtmux = "tmux source-file ~/.config/tmux/tmux.conf";
    
    # Nix shell
    nix-shell = "nix-shell --run zsh";
  };
  
  # Navigation aliases
  navigationAliases = {
    wspc = "cd ${workspace}";
    shared = "cd ${shared}";
    nixc = "cd $HOME/.config/nix";
  };
  
  # Note-taking aliases
  noteAliases = {
    ideas = "nvim ${notetaking}/ideas/Ideas.md";
    todo = "nvim ${notetaking}/checklists/Todo.md";
    prompts = "nvim ${notetaking}/notes/Prompts.md";
    sht = "nvim ${notetaking}/notes/CheatSheets.md";
    sheet = "nvim ${notetaking}/notes/CheatSheets.md";
    plan = "sops --config=${shared}/.sops.yaml ${notetaking}/notes/plan.enc.md";
  };
  
  # Development aliases
  devAliases = {
    be = "bundle exec ";
    ber = "bundle exec rspec ";
    uvr = "uv run ";
    uvrp = "uv run pytest ";
    uvrd = "uv run python manage.py ";
  };
  
  # Personal project aliases
  personalProjectAliases = {
    buy = "nvim ${workspace}/buy.md";
    zshrc = "nvim $HOME/.config/zsh/init.zsh";
    aliases = "nvim $HOME/.config/zsh/aliases.zsh";
    exer = "cd ${workspace}/exercism";
    readm = "cd ${workspace}/readmore-project";
    ebook = "cd ${workspace}/ebookit";
    ebookit = "cd ${workspace}/ebookit/ebookit-extension";
    rinha = "cd ${workspace}/rinha-backend";
    hl = "cd ${workspace}/homelab";
    vista = "cd ${workspace}/vista-valor";
    real = "cd ${workspace}/realiza-monorepo";
  };
  
  # Kubernetes aliases
  k8sAliases = {
    prod = "k9s -n production -c pods";
    stag = "k9s -n staging -c pods";
    set_mini = "kubectl config use-context minikube && kubectl config set-context minikube";
  };
  
  # Work aliases (Agrosmart - conditional)
  workAliases = lib.optionalAttrs cfg.features.workAliases {
    agro = "cd ${workspace}/agrosmart";
    nex = "cd ${workspace}/agrosmart/nexus/nexus-backend";
    farm = "cd ${workspace}/agrosmart/booster/farm-service";
    acc = "cd ${workspace}/agrosmart/booster/account-service";
    field = "cd ${workspace}/agrosmart/booster/booster-field-notebook-service";
    sat = "cd ${workspace}/agrosmart/booster/satellite-image-service";
    geo = "cd ${workspace}/agrosmart/booster/georef-measures-service";
    map = "cd ${workspace}/agrosmart/booster/weather-map-service";
    weat = "cd ${workspace}/agrosmart/booster/weather-forecast-service";
    inf = "cd ${workspace}/agrosmart/booster/booster-infra";
    kong = "cd ${workspace}/agrosmart/booster/booster-api-gateway";
    nexapi = "cd ${workspace}/agrosmart/nexus/nexus-api-gateway";
    key = "cd ${workspace}/agrosmart/booster/keycloak";
  };

in
{
  # Structured aliases for programs.zsh.shellAliases
  structured = baseAliases
    // navigationAliases
    // noteAliases
    // devAliases
    // personalProjectAliases
    // k8sAliases
    // workAliases;
  
  # Config string (if needed for advanced aliases)
  config = ''
    # Advanced aliases that need shell functions can go here
  '';
}
```

**Benefits:**
- Type-checked alias definitions
- Conditional alias sets (work vs personal)
- Variable substitution at build time
- Easy to override or extend

#### Step 2.2: Create `environment.nix`
Environment variables and exports:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
  
  # Build secret exports if enabled
  secretExports = lib.optionalString cfg.secrets.enable ''
    export OPENROUTER_API_KEY_TERMINAL=$(cat /run/secrets/openrouter_terminal)
    export OPENROUTER_API_KEY_COMMIT=$(cat /run/secrets/openrouter_commit)
    export OPENROUTER_API_KEY_AUTOCOMPLETE=$(cat /run/secrets/openrouter_autocomplete)
    export OPENROUTER_API_KEY_CODE_AGENT=$(cat /run/secrets/openrouter_code_agent)
    export CONTEXT7_API_KEY=$(cat /run/secrets/context7_api_key)
    export GITHUB_TOKEN=$(cat /run/secrets/github_token)
  '';

in
{
  shellInit = ''
    # Standard OS variables
    export EDITOR='nvim'
    export VISUAL='nvim'
    export BROWSER='brave'
    export PODMAN_COLOR=true
    export COLORTERM=truecolor
    export DIRENV_DISABLE=1
    
    # Add homebrew to path (Darwin compatibility)
    export PATH=/opt/homebrew/bin:$PATH
    
    ${secretExports}
  '';
  
  loginInit = ''
    # Login shell initialization
  '';
}
```

**Benefits:**
- Centralized environment management
- Conditional secret loading
- Platform-aware PATH configuration

#### Step 2.3: Create `history.nix`
History configuration and settings:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
in
{
  config = ''
    # History configuration
    HISTSIZE=10000
    HISTFILE=~/.zsh_history
    SAVEHIST=$HISTSIZE
    HISTDUP=erase
    
    # History options
    setopt appendhistory
    setopt sharehistory
    setopt hist_ignore_space
    setopt hist_ignore_all_dups
    setopt hist_save_no_dups
    setopt hist_ignore_dups
    setopt hist_find_no_dups
  '';
}
```

#### Step 2.4: Create `keybindings.nix`
Keybindings and vi-mode configuration:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
in
{
  config = ''
    # Vi mode
    ${lib.optionalString cfg.features.viMode "bindkey -v"}
    
    # History search keybindings
    bindkey '^R' history-incremental-search-backward
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
    bindkey '^p' history-beginning-search-backward
    bindkey '^n' history-beginning-search-forward
    
    ${lib.optionalString cfg.features.viMode ''
      # Vi mode specific bindings
      bindkey -M vicmd 'k' history-substring-search-up
      bindkey -M vicmd 'j' history-substring-search-down
    ''}
    
    # Navigation
    bindkey '^[[A' forward-char
    
    # AI command binding
    ${lib.optionalString cfg.features.aiCommand "bindkey '^G' aicmd"}
    
    # FZF history search
    ${lib.optionalString cfg.features.advancedHistory "bindkey '^ ' fzf_history_search_prefix_widget"}
    
    # Enable cursor blinking
    echo -e '\e[5 q'
  '';
}
```

#### Step 2.5: Create `completion.nix`
Completion and fzf-tab configuration:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
in
{
  config = ''
    # Completion settings
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
    
    # FZF tab completion
    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:*' popup-min-size 80 12
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1a --color=always $realpath'
  '';
}
```

#### Step 2.6: Create `plugins.nix`
Plugin management using Nix instead of Zinit:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
in
{
  list = [
    # Syntax highlighting
    {
      name = "zsh-fast-syntax-highlighting";
      src = pkgs.fetchFromGitHub {
        owner = "zdharma-continuum";
        repo = "fast-syntax-highlighting";
        rev = "v1.55";
        sha256 = "sha256-DWVFBoICroKaKgByLmDEo4O+xo6eA8YO792g8t8R7kA=";
      };
    }
    
    # Autosuggestions
    {
      name = "zsh-autosuggestions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-autosuggestions";
        rev = "v0.7.0";
        sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
      };
    }
    
    # Completions
    {
      name = "zsh-completions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-completions";
        rev = "0.35.0";
        sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg=";
      };
    }
    
    # FZF tab completion
    {
      name = "fzf-tab";
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "v1.1.2";
        sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
      };
    }
    
    # History substring search
    {
      name = "zsh-history-substring-search";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-history-substring-search";
        rev = "v1.1.0";
        sha256 = "sha256-qVaqZ9arNBIkbJivRz+NVD0WfUwEfp9PL/C5XQ+GBoQ=";
      };
    }
    
    # Vi mode
    (lib.mkIf cfg.features.viMode {
      name = "zsh-vi-mode";
      src = pkgs.fetchFromGitHub {
        owner = "jeffreytse";
        repo = "zsh-vi-mode";
        rev = "v0.11.0";
        sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
      };
    })
  ];
}
```

**Critical Change:**
- **Eliminates Zinit runtime dependency**
- Uses NixOS's `programs.zsh.plugins` for pure plugin management
- Plugins are fetched at build time, not runtime
- Version-pinned and reproducible

#### Step 2.7: Create `prompt.nix`
PowerLevel10k prompt configuration:

```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
in
{
  shellInit = lib.mkIf cfg.features.powerLevel10k ''
    # Enable Powerlevel10k instant prompt
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi
    
    # Source p10k configuration if it exists
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  '';
  
  # Consider adding p10k as a plugin in plugins.nix instead
}
```

#### Step 2.8: Create `functions/` directory structure

**`functions/default.nix`** - Function registry:
```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
  
  development = import ./development.nix { inherit lib pkgs config; };
  kubernetes = import ./kubernetes.nix { inherit lib pkgs config; };
  navigation = import ./navigation.nix { inherit lib pkgs config; };
  gitAi = import ./git-ai.nix { inherit lib pkgs config; };
  
in
{
  all = lib.concatStringsSep "\n\n" [
    "# Development Functions"
    development.functions
    
    "# Kubernetes Functions"
    kubernetes.functions
    
    "# Navigation Functions"
    navigation.functions
    
    "# Git AI Functions"
    (lib.optionalString cfg.features.aiCommit gitAi.commitFunctions)
    (lib.optionalString cfg.features.aiCommand gitAi.commandFunctions)
  ];
}
```

**`functions/development.nix`**:
```nix
{ lib, pkgs, config, ... }:

{
  functions = ''
    # Automatically creates and runs a phoenix livebook container
    function run_livebook() {
      ${pkgs.docker}/bin/docker run -p 8080:8080 --pull always \
        -u $(id -u):$(id -g) -v $(pwd):/data livebook/livebook
    }
    
    # Convert text to base64 and copy to clipboard
    function b64() {
      echo -n "$1" | ${pkgs.coreutils}/bin/base64 -w 0 | ${pkgs.wl-clipboard}/bin/wl-copy
    }
    
    # Decode base64
    function bb64() {
      echo -n "$1" | ${pkgs.coreutils}/bin/base64 -d
    }
  '';
}
```

**`functions/kubernetes.nix`**:
```nix
{ lib, pkgs, config, ... }:

{
  functions = ''
    # Switch kubernetes contexts using fzf
    function ksc() {
      local contexts=$(${pkgs.kubectl}/bin/kubectl config get-contexts -o name)
      local selected_context=$(echo "''${contexts}" | ${pkgs.fzf}/bin/fzf)
      
      if [ -n "$selected_context" ]; then
        ${pkgs.kubectl}/bin/kubectl config use-context "$selected_context"
      else
        echo "No context selected."
      fi
    }
  '';
}
```

**`functions/navigation.nix`**:
```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.programs.zsh;
  notesDir = "${cfg.workspace.shared}/notetaking";
in
{
  functions = ''
    # Interactive alias selection and execution
    function als() {
      local cmd=$(alias | sed "s/^alias //" | \
        ${pkgs.fzf}/bin/fzf --ansi --height 20 \
          --preview "echo {}" | \
        awk -F'=' '{print $2}' | tr -d "'")
      if [[ -n $cmd ]]; then
        eval "$cmd"
      fi
    }
    
    # Interactive note browser with fzf
    function notes() {
      local NOTES_DIR="${notesDir}"
      emulate -L zsh -o pipefail
      
      if [[ -z "$NOTES_DIR" || ! -d "$NOTES_DIR" ]]; then
        print -u2 "NOTES_DIR not accessible: ''${NOTES_DIR:-<unset>}"
        return 1
      fi
      
      command -v ${pkgs.fzf}/bin/fzf  >/dev/null || { print -u2 "fzf required"; return 1; }
      command -v ${pkgs.neovim}/bin/nvim >/dev/null || { print -u2 "neovim required"; return 1; }
      
      local -a LIST_CMD
      if command -v ${pkgs.fd}/bin/fd >/dev/null; then
        LIST_CMD=(${pkgs.fd}/bin/fd --hidden --follow --absolute-path -t f -e md . "$NOTES_DIR")
      elif command -v ${pkgs.ripgrep}/bin/rg >/dev/null; then
        LIST_CMD=(${pkgs.ripgrep}/bin/rg --hidden -uu -g '**/*.md' -l --no-messages "$NOTES_DIR")
      else
        LIST_CMD=(${pkgs.findutils}/bin/find "$NOTES_DIR" -type f -name '*.md' -print)
      fi
      
      local PREVIEW_CMD
      if command -v ${pkgs.glow}/bin/glow >/dev/null; then
        PREVIEW_CMD='${pkgs.glow}/bin/glow --style dark --width 120 {}'
      elif command -v ${pkgs.bat}/bin/bat >/dev/null; then
        PREVIEW_CMD='${pkgs.bat}/bin/bat --style=numbers --color=always --line-range=:500 {}'
      else
        PREVIEW_CMD='sed -n "1,200p" -- {}'
      fi
      
      local -a picks
      picks=("''${(@f)$(
        "''${LIST_CMD[@]}" \
          | sort -f \
          | ${pkgs.fzf}/bin/fzf --multi \
                --height=80% \
                --reverse \
                --prompt='notes> ' \
                --preview="$PREVIEW_CMD" \
                --preview-window=right,60%,border \
                --bind='ctrl-a:toggle-all'
      )}")
      
      (( ''${#picks} )) || return 0
      
      ${pkgs.neovim}/bin/nvim -- "''${picks[@]}"
    }
  '';
}
```

**`functions/git-ai.nix`**:
```nix
{ lib, pkgs, config, ... }:

{
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
```

**Key improvements in functions:**
- **Absolute package paths**: Every command uses `${pkgs.package}/bin/command`
- **No implicit PATH dependencies**: Explicit Nix store paths
- **Reproducible**: Same function behavior across systems
- **Type-checked at build time**: Nix validates package references

### Phase 3: Testing & Validation

#### Step 3.1: Create testing module
Create `modules/programs/zsh/tests.nix` for validation:

```nix
{ lib, pkgs, config, ... }:

{
  # Test that all required packages are available
  assertions = [
    {
      assertion = config.jvf.programs.zsh.enable -> pkgs ? zsh;
      message = "zsh package must be available";
    }
    {
      assertion = config.jvf.programs.zsh.features.aiCommit ->
        config.sops.secrets ? "openrouter_commit";
      message = "AI commit feature requires openrouter_commit secret";
    }
  ];
}
```

#### Step 3.2: Validation checklist
Before removing `.zsh` files, validate:

- [ ] All aliases work correctly
- [ ] All functions execute without errors
- [ ] Plugins load properly without Zinit
- [ ] History search works
- [ ] Key bindings function correctly
- [ ] AI features work (if secrets available)
- [ ] P10k prompt displays correctly
- [ ] No shell startup errors
- [ ] Completion works as expected

### Phase 4: Migration & Cleanup

#### Step 4.1: Gradual cutover
1. Keep old `.zsh` files temporarily
2. Add new pure Nix configuration alongside
3. Test extensively in new setup
4. Switch `jvf.programs.zsh.enable = true` to use new modules
5. Monitor for issues

#### Step 4.2: Remove legacy files
Once validated, remove:
- `aliases.zsh`
- `init.zsh`
- `plugins.zsh`
- `settings.zsh`
- `secrets.zsh`
- `utils.zsh`

Update `default.nix` to remove `builtins.readFile` calls.

#### Step 4.3: Update documentation
- Update `AGENTS.md` with new module structure
- Document feature flags in main README
- Add examples of customization

## Advanced Features & Future Enhancements

### 1. Per-Project Shell Environments
```nix
# In options.nix
projectEnvironments = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      path = lib.mkOption { type = lib.types.str; };
      env = lib.mkOption { type = lib.types.attrsOf lib.types.str; };
      aliases = lib.mkOption { type = lib.types.attrsOf lib.types.str; };
    };
  });
  default = {};
};
```

### 2. Dynamic Alias Generation
```nix
# Generate cd aliases from workspace projects
lib.mapAttrs' (name: path: 
  lib.nameValuePair name "cd ${path}"
) cfg.workspace.projects
```

### 3. Modular Feature System
```nix
features = {
  ai.enable = true;
  ai.commit.model = "google/gemini-2.5-flash-lite";
  ai.command.model = "openai/gpt-4.1-nano";
  
  navigation.notes.enable = true;
  navigation.notes.directory = "${cfg.workspace.shared}/notetaking";
  
  development.kubernetes.enable = true;
  development.docker.enable = true;
};
```

### 4. Secret Management Abstraction
```nix
# Automatically configure secrets based on enabled features
config.sops.secrets = lib.mkMerge [
  (lib.mkIf cfg.features.ai.commit.enable {
    "openrouter_commit" = { owner = cfg.username; mode = "0400"; };
  })
  (lib.mkIf cfg.features.ai.command.enable {
    "openrouter_terminal" = { owner = cfg.username; mode = "0400"; };
  })
];
```

## Migration Checklist

### Pre-Migration
- [ ] Read through this entire plan
- [ ] Backup current `.zsh` files
- [ ] Test current configuration works
- [ ] Commit current state to git

### Phase 1: Foundation
- [ ] Create `options.nix` with full type system
- [ ] Create new `default.nix` orchestrator
- [ ] Test module loads without errors

### Phase 2: Content Migration
- [ ] Migrate `aliases.zsh` → `aliases.nix`
- [ ] Migrate `secrets.zsh` → `environment.nix`
- [ ] Migrate `settings.zsh` → `history.nix` + `keybindings.nix`
- [ ] Migrate `plugins.zsh` → `plugins.nix` (eliminate Zinit)
- [ ] Migrate `utils.zsh` → `functions/` directory
- [ ] Create `completion.nix`
- [ ] Create `prompt.nix`
- [ ] Test each component independently

### Phase 3: Integration Testing
- [ ] Enable new module configuration
- [ ] Test shell startup time
- [ ] Test all aliases
- [ ] Test all functions
- [ ] Test AI features
- [ ] Test history search
- [ ] Test completions
- [ ] Test key bindings

### Phase 4: Cleanup
- [ ] Remove old `.zsh` files
- [ ] Update `default.nix` imports
- [ ] Run `make format`
- [ ] Run `make lint`
- [ ] Commit changes
- [ ] Update documentation

## Benefits Summary

### Maintainability
- **Type safety**: Nix type system catches errors at build time
- **Single responsibility**: Each file has one clear purpose
- **Composability**: Easy to enable/disable features
- **Version control**: All configuration in declarative Nix

### Performance
- **No Zinit overhead**: Plugins managed by Nix
- **Faster startup**: No runtime plugin manager initialization
- **Build-time resolution**: Package paths resolved during build

### Reliability
- **Reproducible**: Same configuration produces same environment
- **Explicit dependencies**: All packages declared in Nix
- **No runtime failures**: Missing packages caught at build time
- **Atomic updates**: NixOS rollback capability

### Developer Experience
- **Better IDE support**: Nix language servers work better
- **Clear module interface**: Options document themselves
- **Easy customization**: Override specific features
- **Testing**: Can test configuration before activation

## Conclusion

This refactoring transforms the zsh configuration from imperative shell scripts into a declarative, type-safe, composable Nix module system. The migration is designed to be gradual and safe, with clear testing checkpoints at each phase.

The new structure eliminates runtime dependencies (Zinit), improves maintainability through modular organization, and leverages Nix's strengths in package management and reproducibility.

Key outcomes:
- **Zero `.zsh` files**: Everything is pure Nix
- **Type-safe configuration**: Compile-time validation
- **Feature flags**: Easy enable/disable of functionality  
- **Explicit dependencies**: No hidden runtime requirements
- **Better performance**: Eliminated plugin manager overhead
- **Self-documenting**: Options describe the system

This sets a foundation for future enhancements like per-project environments, dynamic configuration, and advanced feature composition.
