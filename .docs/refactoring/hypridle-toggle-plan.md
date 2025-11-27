# Hypridle Toggle Implementation Plan

## Context
The goal is to prevent the system from suspending or idling when a specific flag/toggle is active on the Waybar. This acts as a "Caffeine" mode for tasks that require long processing times without user interaction.

## Architecture

### 1. Strategy: Process Toggling
Instead of using complex inhibit locks, the most reliable method is to toggle the `hypridle` system service/process itself.
- **Enabled State**: `hypridle` process is running. System manages idle events normally.
- **Disabled State**: `hypridle` process is killed. System ignores idle events completely.

### 2. Component Design

#### A. Control Script (`hypridle-control.sh`)
A shell script that serves as the interface between Waybar and the system.
* **Location**: `modules/desktop/hyprland/hypr/scripts/`
* **Functions**: 
    - `status`: Checks if `pgrep -x hypridle` finds a process. Returns JSON for Waybar with appropriate text, class, and tooltip.
    - `toggle`: If running, `pkill hypridle`. If stopped, execute `hypridle &`.

#### B. Waybar Module (`custom/hypridle`)
A custom module definition in Waybar configuration.
* **Trigger**: `on-click` calling the control script's `toggle` function.
* **Update**: `exec` calling the control script's `status` function (polled or signal-based).
* **Visuals**: Uses the JSON return type to change icons/colors based on the state.

#### C. Visual Feedback (Styles)
CSS styling to clearly differentiate states.
* **Active (Idle Enabled)**: Standard system colors (e.g., White/Green).
* **Inactive (Caffeine Mode)**: Warning or Distinct color (e.g., Red/Orange) to indicate safeguards are off.

## Implementation Steps

1.  **Script Creation**:
    Develop the shell script to handle the logic:
    ```bash
    # Pseudo-code
    if [ "$1" == "status" ]; then
      if running; then json_output "active"; else json_output "inactive"; fi
    elif [ "$1" == "toggle" ]; then
      if running; then kill; else start; fi
    fi
    ```

2.  **Waybar Integration**:
    Add the module to `config.jsonc`:
    ```json
    "custom/hypridle": {
        "format": "{}",
        "return-type": "json",
        "exec": "/path/to/script status",
        "on-click": "/path/to/script toggle",
        "interval": 5
    }
    ```

3.  **Styling**:
    Update `style.css`:
    ```css
    #custom-hypridle.active { color: #a6e3a1; }
    #custom-hypridle.inactive { color: #f38ba8; }
    ```

4.  **NixOS Integration**:
    Ensure the script is executable and included in the Nix configuration environment.
