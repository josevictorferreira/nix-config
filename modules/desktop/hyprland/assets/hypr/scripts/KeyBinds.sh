#!/usr/bin/env bash
pkill yad || true

# Binds live in the Lua config (Hyprland >= 0.55) and are no longer greppable
# out of .conf files, so ask the compositor instead. This is strictly better
# than the old text scraping: it lists the binds that are actually active
# (including submaps) and shows the `description = "..."` set on each bind.

KEYBINDS=$(hyprctl -j binds | jq -r '
  # modmask bits, in display order
  def mods($m): [
    {bit: 64, name: "SUPER"},
    {bit:  4, name: "CTRL"},
    {bit:  8, name: "ALT"},
    {bit:  1, name: "SHIFT"}
  ] | map(select((($m / .bit) | floor) % 2 == 1) | .name);

  .[]
  | (mods(.modmask) + [.key] | join(" + ")) as $combo
  | (if (.description // "") != "" then .description
     else ((.dispatcher // "") + (if (.arg // "") != "" then " " + .arg else "" end))
     end) as $what
  | [$combo, $what] | @tsv
' | sort | column -t -s $'\t')

if [[ -z "$KEYBINDS" ]]; then
    echo "No keybinds found."
    exit 1
fi

echo "$KEYBINDS" | rofi -dmenu -i -p "Keybinds" -config ~/.config/rofi/config-keybinds.rasi
