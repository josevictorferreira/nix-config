{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
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
    generateSSHKey = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to generate an SSH key if one doesn't exist";
    };
    fallbackToHTTPS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to fall back to HTTPS clone if SSH clone fails";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.neovim
      # Package and plugins dependencies
      pkgs.fzf
      pkgs.ripgrep
      pkgs.fd
      pkgs.gcc
      pkgs.tree-sitter
      pkgs.glibc
      pkgs.glibc.dev
      pkgs.pkg-config
      pkgs.openssh
    ];
  };
}
