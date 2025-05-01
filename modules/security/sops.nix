{ config, username, configRoot, ... }:

let
  ageKeyFilePath = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
in
{
  sops = {
    defaultSopsFile = "${configRoot}/secrets/secrets.enc.yaml";
    age.keyFile = ageKeyFilePath;
  };

  sops.secrets."anthropic_api_key" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  environment = {
    variables = {
      SOPS_AGE_KEY_FILE = ageKeyFilePath;
    };
  };
}
