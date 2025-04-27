{ pkgs, username, host, ... }:

{
  networking.hostName = "${host}";
  networking.computerName = "${host}";
  networking.localHostName = "${host}";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';

  security.pam.services.sudo_local.enable = true; # manage the file
  security.pam.services.sudo_local.reattach = true; # install pam_reattach
  security.pam.services.sudo_local.touchIdAuth = true; # install pam_tid

  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };
    dock = {
      autohide = true;
      orientation = "bottom";
      show-recents = false;
      tilesize = 48;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      "com.apple.swipescrolldirection" = false;
      "com.apple.sound.beep.feedback" = 0;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };
    loginwindow = {
      GuestEnabled = false;
    };
    # Trackpad settings
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
    # Enable key repeat
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
  };

  environment.shells = with pkgs; [ zsh ];

  environment.variables = {
    K9S_CONFIG_DIR = "$HOME/.config/k9s";
  };

  environment.systemPackages = with pkgs; [
    m-cli
    mas
    pam-reattach
  ];

  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    jetbrains-mono
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
  ];

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  nix.enable = true;

  nix.package = pkgs.nix;

  nix.optimise.automatic = true;

  nix.settings = {
    experimental-features = "nix-command flakes";
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [ "root" username ];
  };

  nix.gc = {
    automatic = true;
    interval = { Day = 7; };
    options = "--delete-older-than 14d";
  };

  system.stateVersion = 4;
}
