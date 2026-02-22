# Aspect: programs-neovim
# Installs neovim + development tooling (LSP servers, formatters, languages).
# NixOS-only: glibc, glibc.dev.
# Clones .nvim config repo via jvf.repositories.
{ ... }:
let
  mkNeovimOptions =
    { lib, ... }:
    {
      options.jvf.programs.neovim = {
        enable = lib.mkEnableOption "neovim, a hyperextensible text editor";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to install the configuration";
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
      cfg = config.jvf.programs.neovim;
      devTools = import ../legacy/_/common/development { inherit pkgs; };
    in
    {
      imports = [ mkNeovimOptions ];

      config = lib.mkIf cfg.enable {
        users.users."${cfg.username}".packages = [
          pkgs.neovim
          pkgs.fzf
          pkgs.ripgrep
          pkgs.fd
          pkgs.gcc
          pkgs.tree-sitter
          pkgs.pkg-config
          pkgs.openssh
          pkgs.cmake
        ]
        ++ devTools.lspServers
        ++ devTools.formatters
        ++ devTools.languages
        ++ (lib.optionals (!isDarwin) [
          pkgs.glibc
          pkgs.glibc.dev
        ]);

        jvf.repositories.users.${cfg.username}.clonedDirs = {
          ".config/nvim" = "git@github.com:josevictorferreira/.nvim.git";
        };
      };
    };
in
{
  flake.modules.nixos.programs-neovim = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-neovim = mkConfig { isDarwin = true; };
}
