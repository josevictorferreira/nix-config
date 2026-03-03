# Aspect: system-locale
# Defines jvf.system.locale options and platform-specific locale/timezone config.
# NixOS: full locale + timezone + extraLocaleSettings.
# Darwin: empty config (no locale settings needed).
_:
let
  mkLocaleOptions =
    { lib, ... }:
    {
      options.jvf.system.locale = {
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
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.locale;
    in
    {
      imports = [ mkLocaleOptions ];

      config =
        if (!isDarwin) then
          {
            time.timeZone = cfg.timeZone;

            i18n = {
              inherit (cfg) defaultLocale;
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
          }
        else
          { };
    };
in
{
  flake.modules.nixos.system-locale = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-locale = mkConfig { isDarwin = true; };
}
