{
  lib,
  pkgs,
  config,
  systemArc,
  ...
}:

let
  cfg = config.jvf.roles.development;
in
{
  imports = [
    ../programs/ghostty.nix
    ../programs/alacritty.nix
    ../programs/kitty.nix
    ../programs/git.nix
    ../programs/neovim.nix
    ../programs/tmux
    ../programs/zsh
  ];

  options.jvf.roles.development.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable development tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs = {
      ghostty.enable = !(lib.strings.hasInfix "darwin" systemArc);
      alacritty.enable = true;
      kitty.enable = true;
      neovim.enable = true;
      zsh.enable = true;
      tmux.enable = true;
      git = {
        enable = true;
        name = "Jose Victor Ferreira";
        email = "root@josevictor.me";
      };
    };

    environment.systemPackages = [
      pkgs.fastfetch
      pkgs.dbeaver-bin
      pkgs.insomnia
      pkgs.curl
      pkgs.gnupg
      pkgs.gnumake
      pkgs.coreutils
      pkgs.gh
      pkgs.eza
      pkgs.fzf
      pkgs.ripgrep
      pkgs.vim
      pkgs.openssl
      pkgs.openssh
      pkgs.wget
      pkgs.tree
      pkgs.xsel
      pkgs.sops
      pkgs.age
      pkgs.zip
      pkgs.unzip
      pkgs.imagemagick
      pkgs.jq
      pkgs.yq
      pkgs.direnv
    ];
  };
}
