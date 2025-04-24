{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "kitty-chat" ''
      #!/bin/zsh

      if tmux has-session -t chat 2>/dev/null; then
        if [[ -z $(pgrep -x "weechat") ]]; then
          $(which zsh) -c 'tmux send-keys -t chat "weechat" C-m'
        fi
        ${pkgs.kitty}/bin/kitty sh -c "tmux attach-session -t chat"
      else
        ${pkgs.kitty}/bin/kitty sh -c "tmux attach-session -t chat"
      fi
    '')
  ];
  xdg.desktopEntries = {
    kitty-chat = {
      name = "kitty-chat";
      exec = "kitty-chat";
      icon = "kitty";
      genericName = "Terminal Chat";
      categories = [ "System" "TerminalEmulator" ];
    };
  };
}
