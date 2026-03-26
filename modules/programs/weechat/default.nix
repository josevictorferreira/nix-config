# Aspect: programs-weechat
# Weechat IRC/matrix client with custom plugins, settings, and secret management.
{ lib, ... }:
let
  weechatModule =
    { config, pkgs, ... }:
    let
      cfg = config.jvf.programs.weechat;

      # Get all scripts (user + defaults)
      allScripts = cfg.plugins.scripts;

      # Weechat package with configuration
      weechatPkg = pkgs.weechat.override {
        configure =
          { availablePlugins, ... }:
          {
            scripts = allScripts;
            plugins =
              # Map standard plugin names to availablePlugins
              (map (pluginName: availablePlugins.${pluginName}) cfg.plugins.native)
              # Add matrix plugin if enabled
              ++ lib.optional (cfg.matrixPlugin != null) cfg.matrixPlugin;
            init = cfg.initScript;
          };
      };

      # Final package (use user-provided or generated)
      finalPackage = if cfg.package != null then cfg.package else weechatPkg;
    in
    {
      imports = [
        ./options.nix
        ./_/scripts.nix
        ./_/settings.nix
        ./_/commands.nix
        ./_/matrix.nix
        ./_/init.nix
      ];

      config = {
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
