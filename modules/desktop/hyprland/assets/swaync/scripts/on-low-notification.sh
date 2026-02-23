#!/usr/bin/env bash
# Play sound for low urgency notifications
@pulseaudio@/bin/paplay @sound_theme@/share/sounds/freedesktop/stereo/message.oga 2>/dev/null || true
