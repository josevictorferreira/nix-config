{ pkgs, config, ... }:
{
  home = {
    packages = with pkgs; [
      ddcutil
    ];
    file."${config.home.homeDirectory}/.local/bin/adaptive-brightness.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        hour=$(LC_ALL=C date +'%H')

        if [ "$hour" -lt 6 ]; then
          brightness=13
        elif [ "$hour" -lt 9 ]; then
          brightness=21
        elif [ "$hour" -lt 12 ]; then
          brightness=34
        elif [ "$hour" -lt 15 ]; then
          brightness=55
        elif [ "$hour" -lt 18 ]; then
          brightness=34
        elif [ "$hour" -lt 21 ]; then
          brightness=21
        else
          brightness=13
        fi

        for display in $(ddcutil detect --brief | grep -o 'Display [0-9]' | awk '{print $2}'); do
          ddcutil --display "$display" --sleep-multiplier=0.5 setvcp 10 "$brightness"
        done
      '';
    };
  };
  systemd.user.services."adaptive-brightness" = {
    Unit = {
      Description = "Adaptive monitor brightness based on time of day";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/adaptive-brightness.sh";
    };
  };
  systemd.user.timers."adaptive-brightness" = {
    Unit = {
      Description = "Run adaptive brightness script every 15 minutes";
    };
    Timer = {
      OnCalendar = "*-*-* *:00/15:00";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
