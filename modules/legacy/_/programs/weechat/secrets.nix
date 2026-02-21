{ lib
, cfg
,
}:
let
  paths = {
    slack = "/run/secrets/slack_api_token";
    matrixUrl = "/run/secrets/matrix_server_url";
    matrixUser = "/run/secrets/matrix_server_username";
    matrixPass = "/run/secrets/matrix_server_password";
  };
in
{
  inherit paths;

  sops = {
    slack_api_token = {
      path = paths.slack;
      owner = cfg.username;
      mode = "0400";
    };

    matrix_server_url = lib.mkIf cfg.matrix.enable {
      path = paths.matrixUrl;
      owner = cfg.username;
      mode = "0400";
    };

    matrix_server_username = lib.mkIf cfg.matrix.enable {
      path = paths.matrixUser;
      owner = cfg.username;
      mode = "0400";
    };

    matrix_server_password = lib.mkIf cfg.matrix.enable {
      path = paths.matrixPass;
      owner = cfg.username;
      mode = "0400";
    };
  };
}
