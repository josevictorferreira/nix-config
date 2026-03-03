# _/init.nix - Weechat initialization script generation
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
  };

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

  # Slack setup script
  slackSetupScript = pkgs.writeShellScript "weechat-slack-setup" ''
    echo "/secure set slack_token $(cat ${secretPaths.slack})"
  '';

  # Generate weechat init commands
  weechatInit = lib.concatStringsSep "\n" (
    [
      "/exec -oc ${slackSetupScript}"
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

  sops.secrets.slack_api_token = {
    path = secretPaths.slack;
    owner = cfg.username;
    mode = "0400";
  };
}
