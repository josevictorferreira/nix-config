#!/usr/bin/env bash
# Play sound for critical urgency notifications
@pulseaudio@/bin/paplay @sound_theme@/share/sounds/freedesktop/stereo/dialog-warning.oga 2>/dev/null || true
