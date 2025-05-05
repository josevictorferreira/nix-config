{ config, username, configRoot, isDarwin, ... }:

let
  userHomeDir = if isDarwin then "/Users/${username}" else "/home/${username}";
  ageKeyFilePath = "${userHomeDir}/.config/sops/age/keys.txt";
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

  sops.secrets."nordvpn_access_token" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  environment.variables.SOPS_AGE_KEY_FILE = ageKeyFilePath;
}
