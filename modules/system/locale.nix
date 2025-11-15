{ config
, lib
, ...
}:

let
  cfg = config.jvf.system.locale;
in
{
  options.jvf.system.locale = {
    enable = lib.mkEnableOption "locale and timezone configuration" // {
      description = ''
        Whether to enable locale and timezone configuration.
        Sets up system localization settings and timezone.
      '';
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "America/Sao_Paulo";
      description = "System timezone (e.g., 'America/Sao_Paulo').";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale.";
    };

    useConsistentLocale = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use consistent locale settings across all categories.";
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timeZone;

    i18n = {
      defaultLocale = cfg.defaultLocale;
      extraLocaleSettings = lib.mkIf cfg.useConsistentLocale {
        LC_ADDRESS = cfg.defaultLocale;
        LC_IDENTIFICATION = cfg.defaultLocale;
        LC_MEASUREMENT = cfg.defaultLocale;
        LC_MONETARY = cfg.defaultLocale;
        LC_NAME = cfg.defaultLocale;
        LC_NUMERIC = cfg.defaultLocale;
        LC_PAPER = cfg.defaultLocale;
        LC_TELEPHONE = cfg.defaultLocale;
        LC_TIME = cfg.defaultLocale;
      };
    };
  };
}
