# _/init.nix - Weechat initialization script generation
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.jvf.programs.weechat;

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

  # Generate weechat init commands
  weechatInit = lib.concatStringsSep "\n" (
    cfg.prependInitCommands
    ++ [
      "/bar hide nicklist"
    ]
    ++ cfg.autohideFilterCommands
    ++ cfg.extraCommands
    ++ cfg.extraInitCommands or [ ]
    ++ [
      (lib.concatStringsSep "\n" (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings))
    ]
  );
in
{
  jvf.programs.weechat.initScript = lib.mkDefault weechatInit;
}
