{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "kitty-chat" ''
      #!/bin/zsh
      tmux has-session -t chat 2>/dev/null || tmux new-session -d -s chat

      if [[ -z $(pgrep -x "weechat") ]]; then
        $(which zsh) -c 'tmux send-keys -t chat "weechat" C-m'
      fi

      ${pkgs.kitty}/bin/kitty tmux attach-session -t chat
    '')

    (makeDesktopItem {
      name = "kitty-chat";
      exec = "kitty-chat";
      icon = "kitty";
      desktopName = "Kitty Chat";
      genericName = "Terminal Chat";
      categories = [ "System" "TerminalEmulator" ];
    })
  ];
}
