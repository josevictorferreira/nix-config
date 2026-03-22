# Aspect: programs-iamb
# Defines jvf.programs.iamb options for the Iamb Matrix client.
# Config.toml is generated and placed via jvf.wrappers.
{ lib, ... }:
let
  mkIambOptions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.jvf.programs.iamb = {
        package = lib.mkPackageOption pkgs "iamb" { };

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration.";
        };

        userId = lib.mkOption {
          type = lib.types.str;
          default = "@zeh:josevictor.me";
          description = "Matrix user ID (e.g. @user:matrix.example.org).";
        };

        homeserver = lib.mkOption {
          type = lib.types.str;
          default = "https://matrix.josevictor.me";
          description = "Matrix homeserver URL.";
        };

        requestTimeout = lib.mkOption {
          type = lib.types.int;
          default = 300;
          description = "Request timeout in seconds.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.iamb;

      # Generate iamb config.toml content
      iambConfig = ''
        default_profile = "default"

        [profiles.default]
        user_id = "${cfg.userId}"
        url = "${cfg.homeserver}"

        [settings]
        log_level = "warn"
        request_timeout = ${toString cfg.requestTimeout}
        username_display = "username"
        reaction_display = true
        typing_notice_display = true
        typing_notice_send = true
        read_receipt_display = true
        read_receipt_send = true

        [settings.image_preview]
        protocol.type = "sixel"

        [settings.sort]
        rooms = ["unread", "favorite", "lowpriority", "name"]
        members = ["power", "id"]
      '';
    in
    {
      imports = [ mkIambOptions ];

      config = {
        jvf.wrappers.users.${cfg.username}.programs.iamb = {
          packages = lib.optional (!isDarwin) cfg.package;
          command = "${lib.getExe cfg.package}";
          configs = {
            "config.toml" = iambConfig;
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-iamb = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-iamb = mkConfig { isDarwin = true; };
}
