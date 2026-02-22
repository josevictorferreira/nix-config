# Aspect: roles-development
# Bundles core development programs and CLI tools.
# Enables program aspects (ghostty, alacritty, kitty, neovim, zsh, starship, tmux, git)
# and installs user-level dev packages.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.roles.development = {
        enable = lib.mkEnableOption "development tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for installing packages to.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.development;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs = {
          ghostty.enable = true;
          alacritty.enable = true;
          kitty.enable = true;
          neovim.enable = true;
          zsh.enable = true;
          starship.enable = true;
          tmux.enable = true;
          git = {
            enable = true;
            name = "Jose Victor Ferreira";
            email = "root@josevictor.me";
          };
        };

        users.users."${cfg.username}".packages = [
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
          pkgs.bat
          pkgs.brave
          pkgs.p7zip
        ];
      };
    };
in
{
  flake.modules.nixos.roles-development = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-development = mkConfig { isDarwin = true; };
}
