# config/permission.nix - Permission configurations for OpenCode
{ ... }:
{
  config.jvf.programs.opencode.settings.permission = {
    edit = "ask";
    bash = {
      "git status*" = "allow";
      "git log*" = "allow";
      "git diff*" = "allow";
      "git show*" = "allow";
      "git branch*" = "allow";
      "git remote*" = "allow";
      "git config*" = "allow";
      "git rev-parse*" = "allow";
      "git ls-files*" = "allow";
      "git ls-remote*" = "allow";
      "git describe*" = "allow";
      "git tag --list*" = "allow";
      "git blame*" = "allow";
      "git shortlog*" = "allow";
      "git reflog*" = "allow";
      "git add*" = "allow";

      "nix search*" = "allow";
      "nix eval*" = "allow";
      "nix show-config*" = "allow";
      "nix flake show*" = "allow";
      "nix flake check*" = "allow";
      "nix log*" = "allow";

      "ls*" = "allow";
      "pwd*" = "allow";
      "find*" = "allow";
      "grep*" = "allow";
      "rg*" = "allow";
      "cat*" = "allow";
      "head*" = "allow";
      "tail*" = "allow";
      "mkdir*" = "allow";
      "chmod*" = "allow";

      "systemctl list-units*" = "allow";
      "systemctl list-timers*" = "allow";
      "systemctl status*" = "allow";
      "journalctl*" = "allow";
      "dmesg*" = "allow";
      "env*" = "allow";
      "nh search*" = "allow";

      "pactl list*" = "allow";
      "pw-top*" = "allow";

      "git reset*" = "ask";
      "git commit*" = "ask";
      "git push*" = "ask";
      "git pull*" = "ask";
      "git merge*" = "ask";
      "git rebase*" = "ask";
      "git checkout*" = "ask";
      "git switch*" = "ask";
      "git stash*" = "ask";

      "rm*" = "ask";
      "mv*" = "ask";
      "cp*" = "ask";

      "systemctl start*" = "ask";
      "systemctl stop*" = "ask";
      "systemctl restart*" = "ask";
      "systemctl reload*" = "ask";
      "systemctl enable*" = "ask";
      "systemctl disable*" = "ask";

      "curl*" = "ask";
      "wget*" = "ask";
      "ping*" = "ask";
      "ssh*" = "ask";
      "scp*" = "ask";
      "rsync*" = "ask";

      "sudo*" = "ask";
      "nixos-rebuild*" = "ask";

      "kill*" = "ask";
      "killall*" = "ask";
      "pkill*" = "ask";
    };
    read = "allow";
    list = "allow";
    glob = "allow";
    grep = "allow";
    webfetch = "ask";
    write = "ask";
    task = "allow";
    todowrite = "allow";
    todoread = "allow";
  };
}
