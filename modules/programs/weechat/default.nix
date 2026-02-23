# Aspect: programs-weechat
# Weechat IRC/matrix client with custom plugins, settings, and secret management.
# Consolidates legacy modules/legacy/_/programs/weechat/ directory.
{ ... }:
let
  # ── Helper Files (inlined from legacy) ─────────────────────────────────

  # Default settings
  defaultSettings = {
    weechat = {
      bar = {
        input.items = "mode_indicator+[input_prompt]+(away),[input_search], [input_paste],input_text,[vi_buffer]";
        status.items = "[time],[buffer_last_number],buffer_number+:+buffer_name+(buffer_modes)+{buffer_nicklist_count}+buffer_zoom+buffer_filter,scroll,[lag],[hotlist],completion,cmd_completion";
        buflist = {
          position = "left";
          size = "25";
          size_max = "30";
        };
        activetitle = {
          priority = "500";
          conditions = "\${active}";
          color_fg = "white";
          color_bg = "31";
          separator = "on";
        };
        title = {
          conditions = "\${inactive}";
          color_fg = "black";
          color_bg = "31";
        };
        nicklist = {
          color_fg = "229";
          separator = "on";
          conditions = "\${nicklist} && \${window.number} == 1";
          size_max = "20";
          size = "16";
        };
      };
      look = {
        mouse = "on";
        color_nick_offline = "yes";
        buffer_time_format = "\${253}%H\${245}%M";
        prefix_align = "none";
        prefix_align_min = "0";
        prefix_align_max = "14";
        save_config_on_exit = "off";
        prefix_same_nick = "⤷";
        prefix_suffix = "│";
        prefix_action = " •";
        read_marker_string = "─";
        separator_horizontal = "=";
        prefix_network = "▬▬";
        prefix_join = "▬▬▶";
        prefix_quit = "◀▬▬";
        bar_more_down = "▼";
        bar_more_left = "◀";
        bar_more_right = "▶";
        bar_more_up = "▲";
        color_inactive_message = "off";
        color_inactive_prefix = "off";
        color_inactive_prefix_buffer = "off";
        color_inactive_window = "off";
        day_change_message_1date = "▬▬▶ %a, %d %b %Y ◀▬▬";
        day_change_message_2dates = "▬▬▶ %%a, %%d %%b %%Y (%a, %d %b %Y) ◀▬▬";
        item_buffer_filter = "•";
      };
      color = {
        chat_time = "239";
        chat_host = "31";
        chat_nick_colors = "25,31,37,43,49,61,67,73,79,85,97,103,109,115,121,133,139,145,151,157,163,169,175,181,187,193,199,205,211,217,223,229";
        chat_highlight = "lightred";
        chat_highlight_bg = "default";
        bar_more = "229";
        chat_prefix_more = "31";
        chat_prefix_suffix = "31";
        chat_read_marker = "31";
        chat_delimiters = "31";
        separator = "31";
        status_data_highlight = "163";
        status_data_msg = "229";
        status_data_private = "121";
        status_more = "229";
        status_name = "121";
        chat_prefix_join = "121";
        chat_prefix_quit = "131";
      };
      plugin = {
        autoload = "*,!lua,!tcl,!ruby,!fifo,!xfer,!guile,!javascript";
      };
    };
    aspell = {
      check = {
        default_dict = "en";
        suggestions = "3";
      };
      color = {
        suggestions = "*green";
      };
    };
    logger = {
      level = {
        irc = "0";
      };
      mask = {
        irc = "%Y/$server/$channel.%m-%d.log";
      };
    };
    irc = {
      look = {
        server_buffer = "independent";
        smart_filter = "on";
        buffer_switch_autojoin = "off";
        buffer_switch_join = "off";
        color_nicks_in_nicklist = "on";
        part_closes_buffer = "on";
      };
      color = {
        message_join = "121";
        message_quit = "131";
        nick_prefixes = "q:lightred;a:lightcyan;o:121;h:lightmagenta;v:229;*:lightblue";
      };
      server_default = {
        away_check = "5";
        away_check_max_nicks = "25";
      };
      network = {
        ban_mask_default = "*!*@\$host";
      };
    };
    buflist = { };
    plugins.var.python = {
      slack = {
        autoconnect = "off";
        slack_api_token = "\${sec.data.slack_token}";
      };
      vimode = {
        no_warn = "on";
        search_vim = "on";
      };
    };
    plugins.var.perl.highmon.alignment = "nchannel";
  };

  # Default extra commands
  defaultExtraCommands = [
    "/trigger add upgrade_scripts signal day_changed"
    "/trigger set upgrade_scripts command \"/script update\\;/wait 10s \\;/script upgrade\""
    "/alias add cq allpv /buffer close"
    "/alias add slap /me slaps $1 around a bit with a large trout"
    "/alias add customgrep /input delete_line\\;/input insert /grep log */$server/$channel.* -a ^\\[\\d{2}:\\d{2}:\\d{2}\\] <%{escape $1}>\\x20"
    "/alias add ptpburl /exec -sh -hsignal ptpburl $* 2>&1 | curl -sF c=@- https://ptpb.pw/?u=1"
    "/trigger add ptpburl hsignal ptpburl"
    "/trigger set ptpburl command \"/command -buffer \${buffer.full_name} core /input delete_line\\;/command -buffer \${buffer.full_name} core /input insert \${out}\""
    "/key bindctxt cursor @item(buffer_nicklist):v /window \${_window_number}\\;/voice \${nick}"
    "/filter addreplace irc_smart *,!irc.undernet.* irc_smart_filter *"
    "/bar del activetitle"
    "/bar add activetitle window top 1 0 buffer_title"
  ];

  # ── Options ──────────────────────────────────────────────────────────
  mkWeechatOptions =
    { config, lib, ... }:
    {
      options.jvf.programs.weechat = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install configuration";
        };

        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          description = "The weechat package to be used (auto-generated if null)";
        };

        plugins = {
          native = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "python"
              "perl"
              "lua"
              "ruby"
            ];
            description = "Native Weechat plugin names enabled in the wrapped package.";
          };

          scripts = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Script packages installed for Weechat.";
          };
        };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = defaultSettings;
          description = "Settings written via /set during Weechat init.";
        };

        extraCommands = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = defaultExtraCommands;
          description = "Extra Weechat commands executed at startup.";
        };

        autohideFilterCommands = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "/filter add weechat_matrix_discord_categories matrix * * (?i)(^|[[:space:][:punct:]])(category|categories|space|spaces)($|[[:space:][:punct:]])"
          ];
          description = "Filter commands executed at startup to auto-hide category/meta buffers.";
        };

        matrix = {
          enable = lib.mkEnableOption "Matrix protocol support via weechat-matrix-rs";
        };
      };
    };

  # ── Config ───────────────────────────────────────────────────────────
  weechatModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.weechat;

      # Secret paths
      secretPaths = {
        slack = "/run/secrets/slack_api_token";
        matrixUrl = "/run/secrets/matrix_server_url";
        matrixUser = "/run/secrets/matrix_server_username";
        matrixPass = "/run/secrets/matrix_server_password";
      };

      # Matrix plugin (Rust-based)
      weechatMatrixRs =
        let
          pkg = pkgs.rustPlatform.buildRustPackage {
            pname = "weechat-matrix-rs";
            version = "0.1.0-unstable-2025-01-15";

            src = pkgs.fetchFromGitHub {
              owner = "poljar";
              repo = "weechat-matrix-rs";
              rev = "4cc5777b630ba4d6a9c964248531f283178a4717";
              hash = "sha256-CF4xDoRYey9F8/XSW/euNb8IjZXyP6k0Nj61shsmyEo=";
            };

            cargoHash = "sha256-jAlBCmLJfWWAUHd3ySB930iqAVXMh6ueba7xS///Rt0=";

            nativeBuildInputs = with pkgs; [
              pkg-config
              cmake
              rustPlatform.bindgenHook
            ];

            buildInputs = with pkgs; [
              openssl
              weechat
              sqlite
            ];

            postInstall = ''
              mkdir -p $out/lib/weechat/plugins
              cp $out/lib/libmatrix.so $out/lib/weechat/plugins/matrix.so 2>/dev/null || true
              cp $out/lib/libmatrix.dylib $out/lib/weechat/plugins/matrix.so 2>/dev/null || true
            '';

            meta = with lib; {
              description = "Rust Matrix plugin for Weechat";
              homepage = "https://github.com/poljar/weechat-matrix-rs";
              license = licenses.isc;
              platforms = platforms.unix;
            };
          };
        in
        pkg
        // {
          pluginFile = "${pkg}/lib/weechat/plugins/matrix.so";
        };

      # Vimode script
      viModeScript = pkgs.stdenv.mkDerivation {
        pname = "vimode";
        version = "0.8";

        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/GermainZ/weechat-vimode/0ca9a67017302b32c38a6c9e3ffcd5b81f2aea36/vimode.py";
          sha256 = "sha256-YRFIcvTJcGjmcPWOPkTz3DB40fudVcZ1MiT36qi/hyI=";
        };

        dontUnpack = true;
        prePatch = ''
          cp $src vimode.py
        '';

        passthru.scripts = [ "vimode.py" ];

        installPhase = ''
          runHook preInstall
          install -D vimode.py $out/share/vimode.py
          runHook postInstall
        '';

        meta = {
          homepage = "https://github.com/GermainZ/weechat-vimode";
          description = "vi/vim-like modes and keybindings";
          license = lib.licenses.gpl3Plus;
        };
      };

      # Default scripts
      defaultScripts = [
        pkgs.weechatScripts.highmon
        pkgs.weechatScripts.colorize_nicks
        pkgs.weechatScripts.autosort
        pkgs.weechatScripts.weechat-go
        pkgs.weechatScripts.wee-slack
        pkgs.weechatScripts.url_hint
        pkgs.weechatScripts.multiline
        pkgs.weechatScripts.weechat-notify-send
        pkgs.weechatScripts.buffer_autoset
        pkgs.weechatScripts.autosort
        pkgs.weechatScripts.weechat-grep
        viModeScript
      ];

      allScripts = cfg.plugins.scripts ++ defaultScripts;

      # Buflist filter commands
      buflistFilterCommands = [
        # Discord: hide nested (categories and channels), keep only #Discord parent
        ''/filter add buflist_hide_discord_nested * * ^#Discord\..*''
        # WhatsApp: hide contacts, keep only bridge parent
        ''/filter add buflist_hide_whatsapp_nested * * ^#WhatsApp.*\..*''
        # Slack: hide channels, keep only team
        ''/filter add buflist_hide_slack_channels * * ^slack\.[^.]+\..*''
      ];

      allFilterCommands = cfg.autohideFilterCommands ++ buflistFilterCommands;

      # Init script generator
      flattenSettings =
        prefix: attrs:
        lib.concatLists (
          lib.mapAttrsToList
            (
              name: value:
              let
                key = if prefix == "" then name else "${prefix}.${name}";
              in
              if lib.isAttrs value then flattenSettings key value else [{ inherit key value; }]
            )
            attrs
        );

      flattenedSettings = flattenSettings "" cfg.settings;

      matrixSetupScript = pkgs.writeShellScript "weechat-matrix-setup" ''
        echo "/secure set matrix_password $(cat ${secretPaths.matrixPass})"
        echo "/matrix server add homelab-matrix $(cat ${secretPaths.matrixUrl})"
        echo "/set matrix-rust.server.homelab-matrix.username $(cat ${secretPaths.matrixUser})"
        echo "/set matrix-rust.server.homelab-matrix.password $(cat ${secretPaths.matrixPass})"
        echo "/matrix connect homelab-matrix"
      '';

      slackSetupScript = pkgs.writeShellScript "weechat-slack-setup" ''
        echo "/secure set slack_token $(cat ${secretPaths.slack})"
      '';

      weechatInit = lib.concatStringsSep "\n" (
        [
          "/exec -oc ${slackSetupScript}"
          "/bar hide nicklist"
        ]
        ++ allFilterCommands
        ++ cfg.extraCommands
        ++ lib.optionals cfg.matrix.enable [
          "/exec -oc ${matrixSetupScript}"
        ]
        ++ [
          (lib.concatStringsSep "\n" (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings))
        ]
      );

      # Weechat package with configuration
      weechatPkg = pkgs.weechat.override {
        configure =
          { availablePlugins, ... }:
          {
            scripts = allScripts;
            plugins =
              (map (pluginName: availablePlugins.${pluginName}) cfg.plugins.native)
              ++ lib.optionals cfg.matrix.enable [ weechatMatrixRs ];
            init = weechatInit;
          };
      };

      # Final package (use user-provided or generated)
      finalPackage = if cfg.package != null then cfg.package else weechatPkg;

    in
    {
      imports = [ mkWeechatOptions ];

      config = {
        sops.secrets = {
          slack_api_token = {
            path = secretPaths.slack;
            owner = cfg.username;
            mode = "0400";
          };

          matrix_server_url = lib.mkIf cfg.matrix.enable {
            path = secretPaths.matrixUrl;
            owner = cfg.username;
            mode = "0400";
          };

          matrix_server_username = lib.mkIf cfg.matrix.enable {
            path = secretPaths.matrixUser;
            owner = cfg.username;
            mode = "0400";
          };

          matrix_server_password = lib.mkIf cfg.matrix.enable {
            path = secretPaths.matrixPass;
            owner = cfg.username;
            mode = "0400";
          };
        };

        jvf.wrappers.users.${cfg.username}.programs.weechat = {
          packages = [
            finalPackage
            pkgs.aspell
            pkgs.aspellDicts.en
            pkgs.aspellDicts.pt_BR
            pkgs.python3
          ]
          ++ allScripts;
          command = "${lib.getExe finalPackage}";
        };
      };
    };
in
{
  flake.modules.nixos.programs-weechat = weechatModule;
  flake.modules.darwin.programs-weechat = weechatModule;
}
