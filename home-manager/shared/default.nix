{ pkgs, username, host, isDarwin, configRoot, ... }:
let
  homeDirPrefix = if isDarwin then "/Users" else "/home";
  inherit (import "${configRoot}/hosts/${host}/variables.nix") gitUsername gitEmail keyboardLayout;
in
{
  imports = [
    ./zsh.nix
    ./neovim.nix
    ./tmux.nix
    ./weechat.nix
    ./kitty.nix
    ./k9s.nix
  ];

  home = {
    username = "${username}";
    homeDirectory = "${homeDirPrefix}/${username}";

    keyboard = {
      layout = "${keyboardLayout}";
    };

    packages = with pkgs; [
      # Desktop tools
      brave

      # Dev tools
      curl
      git
      gnupg
      gnumake
      coreutils
      insomnia
      gh
      awscli
      kubectl
      k9s
      kubernetes-helm
      helmfile
      htop-vim
      inetutils
      eza
      fzf
      ripgrep
      vim
      openssl
      openssh
      wget
      nmap
      arp-scan
      tree
      direnv
      clang
      xsel
      sops
      age
      unzip
      imagemagick
      btop
      fastfetch
      ffmpeg

      nettools
      lsof
      jq
      yq

      podman
      podman-compose
    ];

    stateVersion = "24.05";
  };

  modules = {
    weechat = {
      enable = true;
      additionalScripts = [ ];
    };
    kitty = {
      enable = true;
    };
  };

  programs = {
    home-manager = {
      enable = true;
    };

    git = {
      enable = true;
      userName = "${gitUsername}";
      userEmail = "${gitEmail}";
      difftastic = {
        enable = true;
      };

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        push.followTags = true;
        pull.rebase = true;
        url = {
          "ssh://git@github.com/" = {
            insteadOf = "https://github.com/";
          };
        };
        fetch = {
          prune = true;
          tags = true;
        };
      };
    };
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
  };

}
