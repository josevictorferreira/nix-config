{ configRoot, pkgs, ... }:

{
  security.pam.services.hyprlock = {
    allowNullPassword = false;
    startSession = false;
    text = ''
      auth include login
      account include login
    '';
  };

  programs = {
    hyprlock.enable = true;
  };
}
