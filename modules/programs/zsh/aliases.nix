{
  config,
  ...
}:

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

    # Common Tools
    bcat = "bat";

    # Better ls
    ls = "eza -a --icons";
    ll = "eza -al --icons";
    lt = "eza -a --tree --level=1 --icons";

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
    k = "kubectl";
    v = "nvim";
    d = "podman";
    dc = "podman-compose";
    docker-compose = "podman-compose";
    docker = "podman";
    m = "make";
    be = "bundle exec ";
    ber = "bundle exec rspec ";
    uvr = "uv run ";
    uvrp = "uv run pytest ";
    uvrd = "uv run python manage.py ";
    rtmux = "tmux source-file ~/.config/tmux/tmux.conf";
  };

  # Personal project aliases
  personalProjectAliases = {
    buy = "nvim ${workspace}/buy.md";
    zshrc = "nvim $HOME/.config/nix/modules/programs/zsh/default.nix";
    aliases = "nvim $HOME/.config/nix/modules/programs/zsh/aliases.nix";
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
  workAliases = {
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

  # Aliases that must be sourced after plugins (specifically to override OH-MY-ZSH)
  lsAliases = ''
    alias ls="eza -a --icons"
    alias ll="eza -al --icons"
    alias lt="eza -a --tree --level=1 --icons"
  '';

in
{
  inherit lsAliases;

  # Structured aliases for programs.zsh.shellAliases
  structured =
    baseAliases
    // navigationAliases
    // noteAliases
    // devAliases
    // personalProjectAliases
    // k8sAliases
    // workAliases;

  # Config string (if needed for advanced aliases)
  shellInit = ''
    # Advanced aliases that need shell functions can go here
  '';
}
