{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  devTools = import ./../common/development { inherit pkgs; };

  cfg = config.jvf.programs.neovim;
in
{
  options.jvf.programs.neovim = {
    enable = lib.mkEnableOption "neovim, a hyperextensible text editor";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the neovim configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${username}".packages = [
      pkgs.neovim
      pkgs.fzf
      pkgs.ripgrep
      pkgs.fd
      pkgs.gcc
      pkgs.tree-sitter
      pkgs.pkg-config
      pkgs.openssh
    ]
    ++ devTools.lspServers
    ++ devTools.formatters
    ++ devTools.languages
    ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
      pkgs.glibc
      pkgs.glibc.dev
    ]);

    jvf.repositories.users.${cfg.username}.clonedDirs = {
      ".config/nvim" = "git@github.com:josevictorferreira/.nvim.git";
    };
  };
}
