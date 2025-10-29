{ pkgs
, username
, host
, isDarwin
, configRoot
, ...
}:
let
  homeDirPrefix = if isDarwin then "/Users" else "/home";
  inherit (import "${configRoot}/hosts/${host}/variables.nix") keyboardLayout;
in
{
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./development
  ];

  home = {
    username = "${username}";
    homeDirectory = "${homeDirPrefix}/${username}";

    keyboard = {
      layout = "${keyboardLayout}";
    };

    packages = with pkgs; [
      # Desktop tools
      insomnia

      # Cli tools
      home-manager
      curl
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

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
