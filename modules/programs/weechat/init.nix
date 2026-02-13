{ lib
, pkgs
, cfg
, settings
, secretPaths
,
}:
let
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

  flattenedSettings = flattenSettings "" settings;

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
in
lib.concatStringsSep "\n" (
  [
    "/exec -oc ${slackSetupScript}"
    "/bar hide nicklist"
  ]
  ++ lib.optionals cfg.matrix.enable [
    "/exec -oc ${matrixSetupScript}"
  ]
  ++ [
    (lib.concatStringsSep "\n" (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings))
  ]
)
