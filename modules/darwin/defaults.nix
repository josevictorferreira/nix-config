# Aspect: darwin-defaults (Darwin only)
# macOS system preferences: Finder, Dock, trackpad, keyboard, global domain.
_: {
  flake.modules.darwin.darwin-defaults =
    { pkgs, ... }:
    {
      # Security & PAM
      security.sudo.extraConfig = ''
        Defaults pwfeedback
      '';

      security.pam.services.sudo_local = {
        enable = true;
        reattach = true;
        touchIdAuth = true;
      };

      # macOS packages
      environment.systemPackages = with pkgs; [
        m-cli
        mas
        pam-reattach
      ];

      # Fonts
      fonts.packages = with pkgs; [
        noto-fonts
        jetbrains-mono
        font-awesome
        nerd-fonts.jetbrains-mono
        nerd-fonts.droid-sans-mono
      ];

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
          ApplePressAndHoldEnabled = false;
        };
        loginwindow = {
          GuestEnabled = false;
        };
        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
        };
      };

      system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
      };
    };
}
