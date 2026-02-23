# aliases/base.nix - Base/utility aliases for ZSH
{ config, lib, ... }:
let
  cfg = config.jvf.programs.zsh;
in
{
  programs.zsh.shellAliases = lib.mkIf cfg.setAsDefaultShell {
    # Navigation Shortcuts
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "~" = "cd ~";
    "-" = "cd -";

    # File Operations
    "cp" = "cp -i";
    "mv" = "mv -i";
    "rm" = "rm -i";
    "mkdir" = "mkdir -p";

    # Quick Edits
    "zshconfig" = "nvim ~/.zshrc";
    "reload" = "source ~/.zshrc";
    "zshenv" = "nvim ~/.zshenv";

    # System Info
    "df" = "df -h";
    "du" = "du -h";
    "free" = "free -h";
    "psaux" = "ps aux";

    # Process Management
    "killport" = "f() { lsof -ti:$1 | xargs kill -9; }; f";
    "ports" = "netstat -tuln";
  };
}
