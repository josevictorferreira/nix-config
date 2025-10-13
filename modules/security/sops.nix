{
  config,
  username,
  configRoot,
  ...
}:

let
  ageKeyFilePath = "/etc/sops/age/keys.txt";
in
{
  sops = {
    defaultSopsFile = "${configRoot}/secrets/secrets.enc.yaml";
    age.keyFile = ageKeyFilePath;
  };

  sops.secrets."nordvpn_access_token" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  sops.secrets."openrouter_api_keys.claude_code" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  sops.secrets."openrouter_api_keys.autocomplete" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  sops.secrets."openrouter_api_keys.terminal" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  sops.secrets."openrouter_api_keys.commits" = {
    owner = config.users.users.${username}.name;
    mode = "0400";
  };

  environment.variables.SOPS_AGE_KEY_FILE = ageKeyFilePath;
}
