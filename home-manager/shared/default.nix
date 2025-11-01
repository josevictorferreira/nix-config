{
  username,
  host,
  isDarwin,
  configRoot,
  ...
}:
let
  homeDirPrefix = if isDarwin then "/Users" else "/home";
  inherit (import "${configRoot}/hosts/${host}/variables.nix") keyboardLayout;
in
{
  home = {
    username = "${username}";
    homeDirectory = "${homeDirPrefix}/${username}";

    keyboard = {
      layout = "${keyboardLayout}";
    };

    stateVersion = "24.05";
  };

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
