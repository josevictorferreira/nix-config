# Aspect: roles-development
# Bundles core development programs and CLI tools.
# Imports program aspects (ghostty, alacritty, kitty, neovim, zsh, starship, tmux, git),
# virtualization (podman, libvirtd), and installs user-level dev packages.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.development = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.development;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-alacritty
        programs-kitty
        programs-neovim
        programs-zsh
        programs-starship
        programs-tmux
        programs-git
        programs-command-code
        system-virtualization
        programs-brave
        programs-brave
        programs-yazi
      ]);

      config = {
        jvf.system.virtualization.username = cfg.username;

        jvf.programs.git = {
          name = "Jose Victor Ferreira";
          email = "root@josevictor.me";
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
          pkgs.p7zip
          pkgs.unrar
        ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.development;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        programs-alacritty
        programs-kitty
        programs-neovim
        programs-zsh
        programs-starship
        programs-tmux
        programs-git
        programs-command-code
        system-virtualization
        programs-brave
        programs-yazi
      ]);

      config = {
        jvf.system.virtualization.username = cfg.username;

        jvf.programs.git = {
          name = "Jose Victor Ferreira";
          email = "root@josevictor.me";
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
          pkgs.p7zip
          pkgs.unrar
        ];
      };
    };
in
{
  flake.modules.nixos.roles-development = nixosModule;
  flake.modules.darwin.roles-development = darwinModule;
}
