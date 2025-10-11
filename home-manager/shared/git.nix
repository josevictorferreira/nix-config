{
  config,
  configRoot,
  host,
  pkgs,
  ...
}:
let
  inherit (import "${configRoot}/hosts/${host}/variables.nix") gitUsername gitEmail;
  preCommit = pkgs.writeShellScript "pre-commit-secrets-check" ''
    #!/usr/bin/env bash
    set -euo pipefail
    fail=0
    for file in $(${pkgs.git}/bin/git diff --cached --name-only -- '*.enc.yaml' '*.enc.yml'); do
      if ! ${pkgs.yq}/bin/yq -e 'has("sops") and (.sops.mac // "" != "")' "$file" >/dev/null 2>&1; then
        echo "❌ ERROR: $file is not encrypted with sops!"
        fail=1
      fi
    done
    if [ $fail -eq 1 ]; then
      echo "Commit aborted. Please encrypt files with: make emanifests"
      exit 1
    fi
  '';
in
{
  home.packages = [
    pkgs.git
    pkgs.yq
  ];

  programs.neovim.enable = true; # ensure nvim is available

  programs.git = {
    enable = true;
    userName = gitUsername;
    userEmail = gitEmail;

    # Optional: pretty structural diffs for `git diff`, unrelated to difftool
    difftastic.enable = true;

    extraConfig = {
      core.hooksPath = "${config.xdg.configHome}/git/hooks";
      core.editor = "nvim";

      # Difftool (use with `git difftool`)
      diff.tool = "nvimdiff";
      difftool.prompt = false;
      # NOTE: single-dollar variables and Nix '' quoting
      difftool.nvimdiff.cmd = ''nvim -d "$LOCAL" "$REMOTE"'';

      # Mergetool (use with `git mergetool`)
      merge.tool = "nvimdiff3";
      mergetool.prompt = false;
      mergetool.keepBackup = false;
      mergetool.nvimdiff3.cmd = ''nvim -d "$LOCAL" "$REMOTE" "$BASE" "$MERGED" -c "wincmd J"'';
      mergetool.nvimdiff3.trustExitCode = true;

      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      push.followTags = true;
      pull.rebase = true;

      url."ssh://git@github.com/".insteadOf = "https://github.com/";

      fetch.prune = true;
      fetch.tags = true;
    };
  };

  xdg.configFile."git/hooks/pre-commit" = {
    source = preCommit;
    executable = true;
  };
}
