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
      spotify

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
      kitty
    ];

    stateVersion = "24.05";
  };

  programs = {
    home-manager = {
      enable = true;
    };

    git = {
      enable = true;
      userName = "${gitUsername}";
      userEmail = "${gitEmail}";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = "true";
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
