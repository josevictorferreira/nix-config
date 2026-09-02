# Aspect: programs-yazi
# Yazi file manager with tokyonight theme, plugins, and shell integration.
# Adapted from khaneliman/khanelinix (d3249ec67bf4ea2d0e93468f149002db4914ed35).
_:
let
  mkYaziOptions =
    { config
    , lib
    , pkgs
    , ...
    }:
    {
      options.jvf.programs.yazi = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install yazi configuration";
        };

        package = lib.mkPackageOption pkgs "yazi" { };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.yazi;
      yaziPlugins = pkgs.yaziPlugins;
      yaziBin = lib.getExe cfg.package;
      kittyBin = lib.getExe pkgs.kitty;

      tokyoNightFlavor = pkgs.fetchFromGitHub {
        owner = "BennyOe";
        repo = "tokyo-night.yazi";
        rev = "8e6296f14daff24151c736ebd0b9b6cd89b02b03";
        hash = "sha256-LArhRteD7OQRBguV1n13gb5jkl90sOxShkDzgEf3PA0=";
      };

      plugins = pkgs.linkFarm "yazi-plugins" [
        {
          name = "chmod.yazi";
          path = yaziPlugins.chmod;
        }
        {
          name = "diff.yazi";
          path = yaziPlugins.diff;
        }
        {
          name = "full-border.yazi";
          path = yaziPlugins.full-border;
        }
        {
          name = "git.yazi";
          path = yaziPlugins.git;
        }
        {
          name = "githead.yazi";
          path = yaziPlugins.githead;
        }
        {
          name = "jump-to-char.yazi";
          path = yaziPlugins.jump-to-char;
        }
        {
          name = "mount.yazi";
          path = yaziPlugins.mount;
        }
        {
          name = "restore.yazi";
          path = yaziPlugins.restore;
        }
        {
          name = "smart-enter.yazi";
          path = yaziPlugins.smart-enter;
        }
        {
          name = "smart-filter.yazi";
          path = yaziPlugins.smart-filter;
        }
        {
          name = "sudo.yazi";
          path = yaziPlugins.sudo;
        }
        {
          name = "toggle-pane.yazi";
          path = yaziPlugins.toggle-pane;
        }
        {
          name = "yatline.yazi";
          path = yaziPlugins.yatline;
        }
        {
          name = "yatline-githead.yazi";
          path = yaziPlugins.yatline-githead;
        }
        {
          name = "wl-clipboard.yazi";
          path = yaziPlugins.wl-clipboard;
        }
      ];

      flavorsDir = pkgs.linkFarm "yazi-flavors" [
        {
          name = "tokyo-night.yazi";
          path = tokyoNightFlavor;
        }
      ];

      yaziDesktopItem = pkgs.makeDesktopItem {
        name = "yazi-fm";
        desktopName = "Yazi File Manager";
        exec = "${kittyBin} --class=yazi-fm -e ${yaziBin} %F";
        icon = "system-file-manager";
        terminal = false;
        type = "Application";
        categories = [
          "System"
          "FileManager"
        ];
        mimeTypes = [
          "inode/directory"
          "application/x-directory"
        ];
      };

      fileManager1Bridge = pkgs.writeShellScriptBin "yazi-filemanager1" ''
        exec ${pkgs.gjs}/bin/gjs ${pkgs.writeText "yazi-filemanager1.js" ''
          const { Gio, GLib } = imports.gi;

          const nodeInfo = Gio.DBusNodeInfo.new_for_xml(`
            <node>
              <interface name="org.freedesktop.FileManager1">
                <method name="ShowItems">
                  <arg name="uris" type="as" direction="in"/>
                  <arg name="startup_id" type="s" direction="in"/>
                </method>
                <method name="ShowFolders">
                  <arg name="uris" type="as" direction="in"/>
                  <arg name="startup_id" type="s" direction="in"/>
                </method>
                <method name="ShowItemProperties">
                  <arg name="uris" type="as" direction="in"/>
                  <arg name="startup_id" type="s" direction="in"/>
                </method>
              </interface>
            </node>
          `);

          function uriToPath(uri) {
            try {
              return Gio.File.new_for_uri(uri).get_path();
            } catch (error) {
              return null;
            }
          }

          function targetPath(path, methodName) {
            if (!path) {
              return null;
            }

            if (methodName === "ShowFolders") {
              return path;
            }

            try {
              const file = Gio.File.new_for_path(path);
              if (file.query_file_type(Gio.FileQueryInfoFlags.NONE, null) === Gio.FileType.DIRECTORY) {
                return path;
              }
            } catch (error) {
              return GLib.path_get_dirname(path);
            }

            return GLib.path_get_dirname(path);
          }

          function openInYazi(path) {
            if (!path) {
              return;
            }

            Gio.Subprocess.new(
              ["${kittyBin}", "--class=yazi-fm", "-e", "${yaziBin}", path],
              Gio.SubprocessFlags.NONE
            );
          }

          function handleMethodCall(_connection, _sender, _objectPath, _interfaceName, methodName, parameters, invocation) {
            const [uris] = parameters.deepUnpack();
            const path = uris.length > 0 ? targetPath(uriToPath(uris[0]), methodName) : null;
            openInYazi(path);
            invocation.return_value(new GLib.Variant("()", []));
          }

          Gio.bus_own_name(
            Gio.BusType.SESSION,
            "org.freedesktop.FileManager1",
            Gio.BusNameOwnerFlags.NONE,
            connection => {
              connection.register_object(
                "/org/freedesktop/FileManager1",
                nodeInfo.interfaces[0],
                handleMethodCall,
                null,
                null
              );
            },
            null,
            null
          );

          new GLib.MainLoop(null, false).run();
        ''}
      '';

      fileManager1Service = pkgs.writeTextDir "share/dbus-1/services/org.freedesktop.FileManager1.service" ''
        [D-BUS Service]
        Name=org.freedesktop.FileManager1
        Exec=${lib.getExe fileManager1Bridge}
      '';

      # Shell wrapper function
      shellWrapperFunction = ''
        function y() {
          local tmp
          tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }
      '';

      initLua = ''
        -- full-border plugin
        require("full-border"):setup()

        -- git plugin
        require("git"):setup()



        -- yatline status line
        local yatline = require("yatline"):setup({
          show_background = false,
          header_line = {
            left = {
              section_separator = { open = "", close = "" },
              part_separator = { open = "", close = "" },
              inverse_separator = { open = "", close = "" },
              style_a = { fg = "black", bg = "blue", bold = true },
              style_b = { fg = "black", bg = "brightblack" },
              style_c = { fg = "white", bg = "black" },
              parts = {
                { { type = "coloreds", custom = false, name = "tab" } },
              },
            },
            right = {
              section_separator = { open = "", close = "" },
              part_separator = { open = "", close = "" },
              inverse_separator = { open = "", close = "" },
              style_a = { fg = "black", bg = "blue", bold = true },
              style_b = { fg = "black", bg = "brightblack" },
              style_c = { fg = "white", bg = "black" },
              parts = {},
            },
          },
          status_line = {
            left = {
              section_separator = { open = "", close = "" },
              part_separator = { open = "", close = "" },
              inverse_separator = { open = "", close = "" },
              style_a = { fg = "black", bg = "blue", bold = true },
              style_b = { fg = "black", bg = "brightblack" },
              style_c = { fg = "white", bg = "black" },
              parts = {
                { { type = "string", custom = false, name = "tab_mode" } },
                { { type = "string", custom = false, name = "hovered_size" } },
                {
                  { type = "string", custom = false, name = "hovered_name" },
                  { type = "coloreds", custom = false, name = "count" },
                },
                {
                  { type = "string", custom = false, name = "selection_size" },
                  { type = "string", custom = false, name = "hovered_mime" },
                },
              },
            },
            right = {
              section_separator = { open = "", close = "" },
              part_separator = { open = "", close = "" },
              inverse_separator = { open = "", close = "" },
              style_a = { fg = "black", bg = "blue", bold = true },
              style_b = { fg = "black", bg = "brightblack" },
              style_c = { fg = "white", bg = "black" },
              parts = {
                {
                  { type = "string", custom = false, name = "cursor_position" },
                },
                {
                  { type = "string", custom = false, name = "cursor_percentage" },
                  { type = "coloreds", custom = false, name = "githead" },
                },
                {
                  { type = "coloreds", custom = false, name = "permissions" },
                },
                {
                  { type = "string", custom = false, name = "hovered_file_extension", params = { true } },
                  { type = "coloreds", custom = false, name = "symlink" },
                },
              },
            },
          },
        })

        -- yatline-githead plugin
        require("yatline-githead"):setup()
      '';

      settingsInput = {
        cursor_blink = false;
        cd_title = "Change Directory";
        cd_origin = "top-left";
        cd_offset = [
          0
          2
          50
          3
        ];
        create_origin = "top-left";
        create_offset = [
          0
          2
          50
          3
        ];
        rename_title = "Rename";
        rename_origin = "top-left";
        rename_offset = [
          0
          1
          50
          3
        ];
        trash_title = "Move {n} selected file(s) to trash? (y/N)";
        trash_origin = "top-left";
        trash_offset = [
          0
          2
          50
          3
        ];
        delete_title = "Permanently delete {n} selected file(s)? (y/N)";
        delete_origin = "top-left";
        delete_offset = [
          0
          2
          50
          3
        ];
        filter_title = "Filter";
        filter_origin = "top-left";
        filter_offset = [
          0
          2
          50
          3
        ];
        find_title = [
          "Find"
          "Find (backwards)"
        ];
        find_origin = "top-left";
        find_offset = [
          0
          2
          50
          3
        ];
        search_title = "Search via {n}";
        search_origin = "top-left";
        search_offset = [
          0
          2
          50
          3
        ];
        shell_title = [
          "Shell"
          "Shell (blocking)"
        ];
        shell_origin = "top-left";
        shell_offset = [
          0
          2
          50
          3
        ];
        overwrite_title = "Overwrite an existing file? (y/N)";
        overwrite_origin = "top-left";
        overwrite_offset = [
          0
          2
          50
          3
        ];
        quit_title = "Quit? (y/N)";
        quit_origin = "top-left";
        quit_offset = [
          0
          2
          50
          3
        ];
      };

      settingsOpen = {
        rules = [
          {
            name = "*.zip";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.tar";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.tar.gz";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.tar.bz2";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.tar.xz";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.tar.zst";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.gz";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.bz2";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.7z";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.rar";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            name = "*.xz";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/zip";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/gzip";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/x-tar";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/x-bzip";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/x-bzip2";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/x-7z-compressed";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/x-rar-compressed";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "application/x-xz";
            use = [
              "archive"
              "extract"
              "open"
            ];
          }
          {
            mime = "video/*";
            use = [
              "play"
              "open"
            ];
          }
          {
            mime = "audio/*";
            use = [
              "play"
              "open"
            ];
          }
          {
            mime = "image/*";
            use = [
              "image"
              "open"
            ];
          }
          {
            mime = "text/*";
            use = [
              "edit"
              "open"
            ];
          }
          {
            mime = "application/json";
            use = [
              "edit"
              "open"
            ];
          }
          {
            mime = "*";
            use = [ "open" ];
          }
        ];
      };

      settingsOpener = {
        edit = [
          {
            run = ''$EDITOR "$@"'';
            block = true;
            desc = "$EDITOR";
          }
        ];
        open =
          lib.optional isDarwin
            {
              run = ''open "$@"'';
              desc = "Open";
            }
          ++ lib.optional (!isDarwin) {
            run = ''hyprctl activewindow | grep -q "class: yazi-fm" && hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'; xdg-open "$@"'';
            orphan = true;
            desc = "Open";
            for = "unix";
          };
        reveal =
          lib.optional isDarwin
            {
              run = ''open -R "$@"'';
              desc = "Reveal in Finder";
            }
          ++ lib.optional (!isDarwin) {
            run = ''hyprctl activewindow | grep -q "class: yazi-fm" && hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'; xdg-open "$(dirname "$0")"'';
            desc = "Reveal in file manager";
            for = "unix";
          };
        extract = [
          {
            run = ''ouch decompress "$@"'';
            desc = "Extract with ouch";
          }
        ];
        play = [
          {
            run = ''hyprctl activewindow | grep -q "class: yazi-fm" && hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'; mpv "$@"'';
            orphan = true;
            for = "unix";
          }
          {
            run = ''mpv "$@"'';
            orphan = true;
            for = "windows";
          }
        ];
        image = [{ run = ''hyprctl activewindow | grep -q "class: yazi-fm" && hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'; eog "$@"''; orphan = true; for = "unix"; }];
        archive = [{ run = ''hyprctl activewindow | grep -q "class: yazi-fm" && hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'; file-roller "$@"''; orphan = true; for = "unix"; }];
      };

      settingsPlugin = {
        prepend_fetchers = [
          {
            id = "git";
            name = "*/";
            run = "git";
          }
          {
            id = "git";
            name = "*";
            run = "git";
          }
        ];
        prepend_previewers = [ ];
        prepend_preloaders = [ ];
        previewers = [
          {
            name = "*/";
            run = "folder";
            sync = true;
          }
          {
            mime = "text/*";
            run = "code";
          }
          {
            mime = "image/*";
            run = "image";
          }
          {
            mime = "video/*";
            run = "video";
          }
          {
            mime = "application/json";
            run = "json";
          }
          {
            mime = "application/pdf";
            run = "pdf";
          }
          {
            mime = "application/*";
            run = "hexyl";
          }
          {
            name = "*";
            run = "file";
          }
        ];
      };

      keymapCompletion = {
        cmp.prepend_keymap = [
          {
            on = "<C-k>";
            run = "arrow -1";
            desc = "Move cursor up";
          }
          {
            on = "<C-j>";
            run = "arrow 1";
            desc = "Move cursor down";
          }
          {
            on = "<Tab>";
            run = "close --submit";
            desc = "Submit";
          }
          {
            on = "<C-q>";
            run = "close";
            desc = "Cancel completion";
          }
          {
            on = "<Esc>";
            run = "close";
            desc = "Cancel completion";
          }
        ];
      };

      keymapHelp = {
        help.prepend_keymap = [
          {
            on = "<C-k>";
            run = "arrow -1";
            desc = "Move cursor up";
          }
          {
            on = "<C-j>";
            run = "arrow 1";
            desc = "Move cursor down";
          }
        ];
      };

      keymapSelect = {
        select.prepend_keymap = [
          {
            on = "<C-k>";
            run = "arrow -1";
            desc = "Move cursor up";
          }
          {
            on = "<C-j>";
            run = "arrow 1";
            desc = "Move cursor down";
          }
        ];
      };

      keymapTasks = {
        tasks.prepend_keymap = [
          {
            on = "<C-k>";
            run = "arrow -1";
            desc = "Move cursor up";
          }
          {
            on = "<C-j>";
            run = "arrow 1";
            desc = "Move cursor down";
          }
          {
            on = "w";
            run = "close";
            desc = "Hide task manager";
          }
        ];
      };

      keymapGoto =
        let
          homeDir = "/home/${cfg.username}";
          darwinHome = "/Users/${cfg.username}";
          home = if isDarwin then darwinHome else homeDir;
        in
        [
          {
            on = [
              "g"
              "h"
            ];
            run = "cd ~";
            desc = "Go home";
          }
          {
            on = [
              "g"
              "c"
            ];
            run = "cd ${home}/.config";
            desc = "Go to config";
          }
          {
            on = [
              "g"
              "d"
            ];
            run = "cd ${home}/Documents";
            desc = "Go to Documents";
          }
          {
            on = [
              "g"
              "D"
            ];
            run = "cd ${home}/Downloads";
            desc = "Go to Downloads";
          }
          {
            on = [
              "g"
              "p"
            ];
            run = "cd ${home}/Pictures";
            desc = "Go to Pictures";
          }
          {
            on = [
              "g"
              "v"
            ];
            run = "cd ${home}/Videos";
            desc = "Go to Videos";
          }
          {
            on = [
              "g"
              "m"
            ];
            run = "cd ${home}/Music";
            desc = "Go to Music";
          }
          {
            on = [
              "g"
              "P"
            ];
            run = "cd ${home}/Projects";
            desc = "Go to Projects";
          }
        ]
        ++ lib.optionals (!isDarwin) [
          {
            on = [
              "g"
              "r"
            ];
            run = "cd /";
            desc = "Go to root";
          }
          {
            on = [
              "g"
              "n"
            ];
            run = "cd /nix/store";
            desc = "Go to nix store";
          }
          {
            on = [
              "g"
              "e"
            ];
            run = "cd /etc";
            desc = "Go to /etc";
          }
          {
            on = [
              "g"
              "M"
            ];
            run = "cd /media";
            desc = "Go to /media";
          }
          {
            on = [
              "g"
              "u"
            ];
            run = "cd /run/media/${cfg.username}";
            desc = "Go to /run/media";
          }
          {
            on = [
              "g"
              "t"
            ];
            run = "cd /tmp";
            desc = "Go to /tmp";
          }
        ]
        ++ lib.optionals isDarwin [
          {
            on = [
              "g"
              "a"
            ];
            run = "cd /Applications";
            desc = "Go to Applications";
          }
          {
            on = [
              "g"
              "V"
            ];
            run = "cd /Volumes";
            desc = "Go to Volumes";
          }
        ];

      keymapNavigation = [
        {
          on = "H";
          run = "back";
          desc = "Go back in history";
        }
        {
          on = "L";
          run = "forward";
          desc = "Go forward in history";
        }
        {
          on = "G";
          run = "arrow 99999999";
          desc = "Move cursor to bottom";
        }
        {
          on = "<C-k>";
          run = "seek -5";
          desc = "Seek up 5 units";
        }
        {
          on = "<C-j>";
          run = "seek 5";
          desc = "Seek down 5 units";
        }
        {
          on = "<Tab>";
          run = "tab_switch 1 --relative";
          desc = "Switch to next tab";
        }
        {
          on = "<S-Tab>";
          run = "tab_switch -1 --relative";
          desc = "Switch to prev tab";
        }
        {
          on = "1";
          run = "tab_switch 0";
          desc = "Switch to tab 1";
        }
        {
          on = "2";
          run = "tab_switch 1";
          desc = "Switch to tab 2";
        }
        {
          on = "3";
          run = "tab_switch 2";
          desc = "Switch to tab 3";
        }
        {
          on = "4";
          run = "tab_switch 3";
          desc = "Switch to tab 4";
        }
        {
          on = "5";
          run = "tab_switch 4";
          desc = "Switch to tab 5";
        }
        {
          on = "6";
          run = "tab_switch 5";
          desc = "Switch to tab 6";
        }
        {
          on = "7";
          run = "tab_switch 6";
          desc = "Switch to tab 7";
        }
        {
          on = "8";
          run = "tab_switch 7";
          desc = "Switch to tab 8";
        }
        {
          on = "9";
          run = "tab_switch 8";
          desc = "Switch to tab 9";
        }
      ];

      keymapOperation = [
        {
          on = [
            "<C-s>"
            "s"
          ];
          run = "plugin sudo --args=paste";
          desc = "Paste as root";
        }
        {
          on = [
            "<C-s>"
            "m"
          ];
          run = "plugin sudo --args=rename";
          desc = "Rename as root";
        }
        {
          on = [
            "<C-s>"
            "d"
          ];
          run = "plugin sudo --args=remove";
          desc = "Remove as root";
        }
        {
          on = [
            "<C-s>"
            "c"
          ];
          run = "plugin sudo --args=create";
          desc = "Create as root";
        }
        {
          on = [
            "<C-s>"
            "r"
          ];
          run = "plugin sudo --args=shell";
          desc = "Shell as root";
        }
        {
          on = "R";
          run = "plugin restore";
          desc = "Restore from trash";
        }
      ];

      keymapManager = {
        mgr.prepend_keymap =
          keymapGoto
          ++ keymapNavigation
          ++ keymapOperation
          ++ [
            {
              on = "f";
              run = "plugin smart-filter";
              desc = "Smart filter";
            }
            {
              on = "<Enter>";
              run = "plugin smart-enter";
              desc = "Smart enter";
            }
            {
              on = "F";
              run = "plugin jump-to-char";
              desc = "Jump to char";
            }
            {
              on = "M";
              run = "plugin mount";
              desc = "Mount manager";
            }
            {
              on = "ch";
              run = "plugin chmod";
              desc = "Chmod";
            }
            {
              on = "md";
              run = "plugin mount --args=mount";
              desc = "Mount";
            }
            {
              on = "mu";
              run = "plugin mount --args=unmount";
              desc = "Unmount";
            }
            {
              on = "mp";
              run = "plugin toggle-pane";
              desc = "Toggle pane";
            }
          ]
          ++ lib.optionals (!isDarwin) [
            {
              on = "y";
              run = [
                "yank"
                "plugin wl-clipboard --args=copy"
              ];
              desc = "Copy to clipboard";
            }
            {
              on = "Y";
              run = [
                "yank --cut"
                "plugin wl-clipboard --args=cut"
              ];
              desc = "Cut to clipboard";
            }
            {
              on = "<Esc>";
              # Three quoting layers: yazi's '...', the shell's "...", and the
              # Lua string. [[yazi]] is a Lua long-bracket string, so it needs
              # no quote characters of its own.
              run = "shell 'hyprctl dispatch \"hl.dsp.workspace.toggle_special([[yazi]])\"'";
              desc = "Hide scratchpad";
            }
          ]
          ++ lib.optionals isDarwin [
            {
              on = "<Esc>";
              run = "quit";
              desc = "Quit";
            }
          ];
      };

      tomlSettings = {
        input = settingsInput;
        open = settingsOpen;
        opener = settingsOpener;
        plugin = settingsPlugin;
        manager = {
          linemode = "size";
          show_hidden = false;
          show_symlink = true;
          sort_by = "alphabetical";
          sort_dir_first = true;
          sort_sensitive = false;
          sort_reverse = false;
        };
        preview = {
          tab_size = 2;
          max_width = 600;
          max_height = 900;
          cache_dir = "";
          image_filter = "lanczos3";
          image_quality = 75;
          sixel_fraction = 15;
          ueberzug_scale = 1;
          ueberzug_offset = [
            0
            0
            0
            0
          ];
        };
        log = {
          enabled = false;
        };
        tasks = {
          micro_workers = 10;
          macro_workers = 25;
          bizarre_retry = 5;
          image_alloc = 536870912;
          image_bound = [
            0
            0
          ];
          suppress_preload = false;
        };
      };

      tomlKeymap = keymapCompletion // keymapHelp // keymapSelect // keymapTasks // keymapManager;

      tomlTheme = {
        flavor = {
          dark = "tokyo-night";
          light = "tokyo-night";
        };
      };
    in
    {
      imports = [ mkYaziOptions ];

      config = {
        jvf.wrappers.users.${cfg.username}.programs.yazi = {
          packages = [
            cfg.package
            pkgs.exiftool
            pkgs.mediainfo
            pkgs.atool
            pkgs.bat
            pkgs.eza
            pkgs.glow
            pkgs.file
          ]
          ++ lib.optionals (!isDarwin) [ pkgs.wl-clipboard ];
        };

        programs.zsh.interactiveShellInit = shellWrapperFunction;

        jvf.home.users.${cfg.username}.items = {
          ".config/yazi/init.lua" = {
            kind = "file";
            mode = "copy";
            text = initLua;
          };

          ".config/yazi/yazi.toml" = {
            kind = "file";
            mode = "copy";
            toml = tomlSettings;
          };

          ".config/yazi/keymap.toml" = {
            kind = "file";
            mode = "copy";
            toml = tomlKeymap;
          };

          ".config/yazi/theme.toml" = {
            kind = "file";
            mode = "copy";
            toml = tomlTheme;
          };

          ".config/yazi/plugins" = {
            kind = "dir";
            mode = "link";
            source = plugins;
          };

          ".config/yazi/flavors" = {
            kind = "dir";
            mode = "link";
            source = flavorsDir;
          };
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        users.users."${cfg.username}".packages = [
          yaziDesktopItem
          fileManager1Service
        ];
      };
    };
in
{
  flake.modules.nixos.programs-yazi = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-yazi = mkConfig { isDarwin = true; };
}
