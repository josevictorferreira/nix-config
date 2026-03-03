# Aspect: desktop-hyprland-fastfetch (NixOS only)
# Fastfetch settings for Hyprland. Configs generated from theme colors.
_: {
  flake.modules.nixos.desktop-hyprland-fastfetch =
    { config, lib, ... }:
    let
      cfg = config.jvf.desktop.hyprland.fastfetch;
      c = config.jvf.theme.colors;

      yellow = "#${c.color3}";
      blue = "#${c.color4}";
      green = "#${c.color2}";
      magenta = "#${c.color5}";
      red = "#${c.color1}";

      configJsonc = ''
        {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {
          "source": "~/.config/fastfetch/nixos.png",
          "type": "kitty-direct",
          "padding": {
            "top": 1
            }
          },
        "display": {
        "separator": " 󰑃  "
        },
        "modules": [
            "break",
            {
            "type": "os",
            "key": " DISTRO",
            "keyColor": "${yellow}"
            },
            {
            "type": "kernel",
            "key": "│ ├",
            "keyColor": "${yellow}"
            },
            {
            "type": "packages",
            "key": "│ ├󰏖",
            "keyColor": "${yellow}"
            },
            {
            "type": "shell",
            "key": "│ └",
            "keyColor": "${yellow}"
            },
            {
            "type": "wm",
            "key": " DE/WM",
            "keyColor": "${blue}"
            },
            {
            "type": "wmtheme",
            "key": "│ ├󰉼",
            "keyColor": "${blue}"
            },
            {
            "type": "icons",
            "key": "│ ├󰀻",
            "keyColor": "${blue}"
            },
            {
                "type": "cursor",
                "key": "│ ├",
                "keyColor": "${blue}"
            },
            {
                "type": "terminalfont",
                "key": "│ ├",
                "keyColor": "${blue}"
            },
            {
            "type": "terminal",
            "key": "│ └",
            "keyColor": "${blue}"
            },
            {
            "type": "host",
            "key": "󰌢 SYSTEM",
            "keyColor": "${green}"
            },
            {
            "type": "cpu",
            "key": "│ ├󰻠",
            "keyColor": "${green}"
            },
            {
            "type": "gpu",
            "key": "│ ├󰻑",
            "format": "{2}",
            "keyColor": "${green}"
            },
            {
                    "type": "display",
            "key": "│ ├󰍹",
            "keyColor": "${green}",
            "compactType": "original-with-refresh-rate"
            },
            {
            "type": "memory",
            "key": "│ ├󰾆",
            "keyColor": "${green}"
            },
            {
            "type": "swap",
            "key": "│ ├󰓡",
            "keyColor": "${green}"
            },
            {
            "type": "uptime",
            "key": "│ ├󰅐",
            "keyColor": "${green}"
            },
            {
            "type": "display",
            "key": "│ └󰍹",
            "keyColor": "${green}"
            },
            {
            "type": "sound",
            "key": " AUDIO",
            "format": "{2}",
            "keyColor": "${magenta}"
            },
            {
            "type": "player",
            "key": "│ ├󰥠",
            "keyColor": "${magenta}"
            },
            {
            "type": "media",
            "key": "│ └󰝚",
            "keyColor": "${magenta}"
            },
            {
            "type": "custom",
            "format": "\u001b[90m  \u001b[31m  \u001b[32m  \u001b[33m  \u001b[34m  \u001b[35m  \u001b[36m  \u001b[37m  \u001b[38m  \u001b[39m  \u001b[39m    \u001b[38m  \u001b[37m  \u001b[36m  \u001b[35m  \u001b[34m  \u001b[33m  \u001b[32m  \u001b[31m  \u001b[90m "
            },
            "break"
            ]
        }
      '';

      configV2Jsonc = ''
        {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {
          "height": 15,
          "width": 30,
          "padding": {
            "top": 1
            }
          },
        "display": {
          "separator": " ➜  "
        },

        "modules": [
          "break",
          {
            "type": "os",
            "key": " DISTRO",
            "keyColor": "${red}"
          },
          {
            "type": "kernel",
            "key": " ├  ",
            "keyColor": "${red}"
          },
          {
            "type": "packages",
            "key": " ├ 󰏖 ",
            "keyColor": "${red}"
          },
          {
            "type": "shell",
            "key": " └  ",
            "keyColor": "${red}"
          },
          "break",
          {
            "type": "wm",
            "key": " DE/WM",
            "keyColor": "${green}"
          },
          {
            "type": "wmtheme",
            "key": " ├ 󰉼 ",
            "keyColor": "${green}"
          },
          {
            "type": "icons",
            "key": " ├ 󰀻 ",
            "keyColor": "${green}"
          },
          {
            "type": "cursor",
            "key": " ├  ",
            "keyColor": "${green}"
          },
          {
            "type": "terminal",
            "key": " ├  ",
            "keyColor": "${green}"
          },
          {
            "type": "terminalfont",
            "key": " └  ",
            "keyColor": "${green}"
          },
          "break",
          {
            "type": "host",
            "format": "{2}",
            "key": "󰌢 SYSTEM",
            "keyColor": "${yellow}"
          },
          {
            "type": "cpu",
            "format": "{1} ({3}) @ {7} GHz",
            "key": " ├  ",
            "keyColor": "${yellow}"
          },
          {
            "type": "gpu",
            "format": "{2}",
            "key": " ├ 󰢮 ",
            "keyColor": "${yellow}"
          },
          {
            "type": "memory",
            "key": " ├  ",
            "keyColor": "${yellow}"
          },
          {
            "type": "swap",
            "key": " ├ 󰓡 ",
            "keyColor": "${yellow}"
          },
          {
            "type": "disk",
            "key": " ├ 󰋊 ",
            "keyColor": "${yellow}"
          },
          {
            "type": "display",
            "key": " └  ",
            "compactType": "original-with-refresh-rate",
            "keyColor": "${yellow}"
          },
          "break",
          "break"
        ]
        }
      '';

      configCompactJsonc = ''
        {
            "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
         "logo": {
          "source": "~/.config/fastfetch/nixos.png",
          "type": "kitty-direct",
          "height": 10,
          "width": 20,
          "padding": {
            "top": 1
            }
          },
            "display": {
                "separator": " -> "
            },
            "modules": [
                "break",
                {
                    "type": "title",
                    "keyWidth": 10,
        			"format": "         {6}{7}{8}"
                },
                {
                    "type": "custom",
                    "format": "  ╭───────────────────────╮"
                },
                {
                    "type": "kernel",
                    "key": " ",
                    "keyColor": "${yellow}"
                },
                {
                    "type": "wm",
                    "key": " ",
                    "keyColor": "${blue}"
                },
                {
                    "type": "shell",
                    "key": " ",
                    "keyColor": "${yellow}"
                },
                {
                    "type": "terminal",
                    "key": " ",
                    "keyColor": "${blue}"
                },
                {
                    "type": "memory",
                    "key": "󰍛 ",
                    "keyColor": "${magenta}",
                    "format": "{1} / {2}"
                },
                {
                    "type": "uptime",
                    "key": "󰔛 ",
                    "keyColor": "${green}"
                },
                {
                    "type": "custom",
                    "format": "  ╰───────────────────────╯"
                },
                {
                    "type": "custom",
                    "format": "   \u001b[31m  \u001b[32m  \u001b[33m  \u001b[34m  \u001b[35m  \u001b[36m  \u001b[37m  \u001b[90m "
                },
        		"break"
            ]
        }
      '';
    in
    {
      options.jvf.desktop.hyprland.fastfetch = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure fastfetch";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.fastfetch = {
          packages = [ ];
          configs = {
            "nixos.png" = ./assets/fastfetch/nixos.png;
            "config.jsonc" = configJsonc;
            "config-v2.jsonc" = configV2Jsonc;
            "config-compact.jsonc" = configCompactJsonc;
          };
        };
      };
    };
}
