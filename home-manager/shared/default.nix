{ pkgs, username, host, isDarwin, configRoot, ... }:
let
  homeDirPrefix = if isDarwin then "/Users" else "/home";
  inherit (import "${configRoot}/hosts/${host}/variables.nix") keyboardLayout;
in
{
  imports = [
    ./git.nix
    ./zsh.nix
    ./neovim.nix
    ./tmux.nix
    ./weechat.nix
    ./kitty.nix
    ./ghostty.nix
    ./k9s.nix
    ./alacritty.nix
    ./btop.nix
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
      insomnia

      # Cli tools
      home-manager
      curl
      git
      gnupg
      gnumake
      coreutils
      gh
      awscli
      kubectl
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
      xsel
      sops
      age
      zip
      unzip
      imagemagick
      btop
      fastfetch
      ffmpeg
      nettools
      lsof
      jq
      yq
      dig
      ncdu # Find large files

      direnv

      claude-code
    ];

    stateVersion = "24.05";
  };

  modules = {
    weechat = {
      enable = true;
      additionalScripts = [ ];
    };
    kitty.enable = true;
    alacritty.enable = true;
  };

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
