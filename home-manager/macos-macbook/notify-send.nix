{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (writeShellScriptBin "notify-send" ''
      #!/bin/bash
      # notify-send for macOS
      # A script that mimics the Linux notify-send command but uses macOS notification system

      # Default values
      TIMEOUT=5000  # Display time in milliseconds (not used in macOS but kept for compatibility)
      URGENCY="normal"
      ICON=""
      APP_NAME="Terminal"

      # Function to show usage information
      show_usage() {
          echo "Usage: notify-send [OPTIONS] <summary> [body]"
          echo "  -u, --urgency=LEVEL       Specify the urgency level (low, normal, critical)"
          echo "  -t, --expire-time=TIME    Time in milliseconds the notification should be displayed"
          echo "  -i, --icon=ICON           Specify an icon filename or stock icon to display"
          echo "  -a, --app-name=APP_NAME   Specify the app name for the icon"
          echo "  -h, --help                Show this help"
          exit 0
      }

      # Parse options
      while [ $# -gt 0 ]; do
          case "$1" in
              -u|--urgency)
                  URGENCY="$2"
                  shift 2
                  ;;
              --urgency=*)
                  URGENCY="''${1#*=}"
                  shift
                  ;;
              -t|--expire-time)
                  TIMEOUT="$2"
                  shift 2
                  ;;
              --expire-time=*)
                  TIMEOUT="''${1#*=}"
                  shift
                  ;;
              -i|--icon)
                  ICON="$2"
                  shift 2
                  ;;
              --icon=*)
                  ICON="''${1#*=}"
                  shift
                  ;;
              -a|--app-name)
                  APP_NAME="$2"
                  shift 2
                  ;;
              --app-name=*)
                  APP_NAME="''${1#*=}"
                  shift
                  ;;
              -h|--help)
                  show_usage
                  ;;
              -*)
                  echo "Unknown option: $1" >&2
                  show_usage
                  ;;
              *)
                  break
                  ;;
          esac
      done

      # Check for required arguments
      if [ $# -lt 1 ]; then
          echo "Error: Missing required argument 'summary'" >&2
          show_usage
      fi

      SUMMARY="$1"
      BODY="''${2:-}"

      # Map urgency levels to macOS sound names
      case "$URGENCY" in
          low)
              SOUND="Tink"
              ;;
          normal)
              SOUND="Ping"
              ;;
          critical)
              SOUND="Sosumi"
              ;;
          *)
              SOUND="Ping"
              ;;
      esac

      # Create and execute the AppleScript
      osascript -e "display notification \"''${BODY}\" with title \"''${SUMMARY}\" sound name \"''${SOUND}\""

      exit 0
    '')
  ];
}
