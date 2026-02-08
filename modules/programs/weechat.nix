{ lib
, pkgs
, config
, username
, ...
}:
let
  cfg = config.jvf.programs.weechat;
  slackSecretPath = "/run/secrets/slack_api_token";
  matrixUrlPath = "/run/secrets/matrix_server_url";
  matrixUserPath = "/run/secrets/matrix_server_username";
  matrixPassPath = "/run/secrets/matrix_server_password";

  # weechat-matrix-rs - Rust Matrix plugin for Weechat
  # https://github.com/poljar/weechat-matrix-rs
  weechatMatrixRs =
    let
      pkg = pkgs.rustPlatform.buildRustPackage rec {
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

        buildInputs =
          with pkgs;
          [
            openssl
            weechat
            sqlite
          ]
          ++ lib.optionals pkgs.stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        # Plugin outputs libmatrix.so
        postInstall = ''
          mkdir -p $out/lib/weechat/plugins
          cp $out/lib/libmatrix.so $out/lib/weechat/plugins/matrix.so || true
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

  weechatSettings = {
    weechat = {
      bar = {
        input.items = "mode_indicator+[input_prompt]+(away),[input_search], [input_paste],input_text,[vi_buffer]";
        status.items = "[time],[buffer_last_number],buffer_number+:+buffer_name+(buffer_modes)+{buffer_nicklist_count}+buffer_zoom+buffer_filter,scroll,[lag],[hotlist],completion,cmd_completion";
        buflist = {
          position = "left";
          size_max = "20";
        };
      };
      look = {
        color_nick_offline = "yes";
        buffer_time_format = "%H:%M";
        prefix_align = "none";
        prefix_align_max = "0";
        save_config_on_exit = "off";
        prefix_same_nick = "⤷";
        prefix_suffix = "│";
        prefix_action = " •";
        read_marker_string = "─";
        separator_horizontal = "";
        prefix_network = "▬▬";
      };
      color = {
        chat_time = "darkgray";
        chat_host = "cyan";
        chat_nick_colors = "1,2,3,4,6,7,9,10,11,12,13,14,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,182,183,184,244,225,226,227";
        chat_highlight = "*16";
        chat_highlight_bg = "9";
      };
    };
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
    vimode = "bind_keys";
  };

  # Flatten nested attrset to dot-notation keys
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

  flattenedSettings = flattenSettings "" weechatSettings;

  weechatInit = lib.concatStringsSep "\n" (
    [
      ''/exec -oc -sh echo "/secure set slack_token $(cat ${slackSecretPath}); /slack connect"''
      "/bar hide nicklist"
    ]
    ++ lib.optionals cfg.matrix.enable [
      ''/exec -oc -sh echo "/secure set matrix_password $(cat ${matrixPassPath}); /matrix server add myserver $(cat ${matrixUrlPath}) $(cat ${matrixUserPath}) \''${sec.data.matrix_password}; /matrix connect myserver"''
    ]
    ++ [
      "/vimode bind_keys"
      (lib.concatStringsSep "\n" (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings))
    ]
  );

  # Commands to run on startup (init commands separated by semicolons for -r flag)
  weechatInitCommands = lib.concatStringsSep ";" (
    [
      ''/exec -oc -sh echo "/secure set slack_token $(cat ${slackSecretPath}); /slack connect"''
      "/bar hide nicklist"
    ]
    ++ lib.optionals cfg.matrix.enable [
      ''/exec -oc -sh 'read -r url < "${matrixUrlPath}"; read -r user < "${matrixUserPath}"; printf "/matrix server add myserver %s\n/set matrix-rust.server.myserver.username %s\n/set matrix-rust.server.myserver.password %s\n/matrix connect myserver\n" "$url" "$user" "''${sec.data.matrix_password}"' ''
    ]
    ++ [
      "/vimode bind_keys"
    ]
    ++ (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings)
  );

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

  weechatPkg = pkgs.weechat.override {
    configure =
      { availablePlugins, ... }:
      {
        scripts = cfg.additionalScripts;
        plugins = [
          availablePlugins.python
          availablePlugins.perl
          availablePlugins.lua
          availablePlugins.ruby
        ]
        ++ lib.optionals cfg.matrix.enable [
          weechatMatrixRs
        ];
        init = weechatInit;
      };
  };

in
{
  options.jvf.programs.weechat = {
    enable = lib.mkEnableOption "weechat, an extensible chat client";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install configuration";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = weechatPkg;
      description = "The weechat package to be used";
    };
    additionalScripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.weechatScripts.highmon
        pkgs.weechatScripts.colorize_nicks
        pkgs.weechatScripts.wee-slack
        pkgs.weechatScripts.url_hint
        pkgs.weechatScripts.multiline
        pkgs.weechatScripts.weechat-notify-send
        viModeScript
      ];
      description = "List of weechat scripts to install in addition to the default set.";
    };
    matrix = {
      enable = lib.mkEnableOption "Matrix protocol support via weechat-matrix-rs";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.slack_api_token = {
      path = "/run/secrets/slack_api_token";
      owner = cfg.username;
      mode = "0400";
    };

    sops.secrets.matrix_server_url = lib.mkIf cfg.matrix.enable {
      path = "/run/secrets/matrix_server_url";
      owner = cfg.username;
      mode = "0400";
    };

    sops.secrets.matrix_server_username = lib.mkIf cfg.matrix.enable {
      path = "/run/secrets/matrix_server_username";
      owner = cfg.username;
      mode = "0400";
    };

    sops.secrets.matrix_server_password = lib.mkIf cfg.matrix.enable {
      path = "/run/secrets/matrix_server_password";
      owner = cfg.username;
      mode = "0400";
    };

    jvf.wrappers.users.${cfg.username}.programs.weechat = {
      packages = [
        cfg.package
        pkgs.aspell
        pkgs.aspellDicts.en
        pkgs.aspellDicts.pt_BR
        pkgs.python3
      ]
      ++ cfg.additionalScripts;
      command = "${lib.getExe cfg.package} -r '${weechatInitCommands}'";
    };
  };
}
