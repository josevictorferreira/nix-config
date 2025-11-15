{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.zsh;
in
{
  options.jvf.programs.zsh = {
    enable = lib.mkEnableOption "zsh, a powerful shell with advanced features";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to clone the zsh configuration";
    };
    setAsDefaultShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to set zsh as the default shell for the user";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    environment = {
      shells = [ pkgs.zsh ];
      variables = {
        ZDOTDIR = "$HOME/.config/zsh";
      };
    };

    jvf.wrappers.users.${cfg.username}.programs.zsh = {
      packages = [
        pkgs.zsh
        pkgs.fzf
        pkgs.ripgrep
        pkgs.direnv
      ];
      configs = {
        "zsh" = ./.;
        ".zshrc" = ''
          source $HOME/.config/zsh/init.zsh
        '';
      };
    };

    users.users.${cfg.username} = lib.mkIf cfg.setAsDefaultShell {
      shell = pkgs.zsh;
    };

    sops.secrets."context7_api_key" = {
      owner = config.users.users.${cfg.username}.name;
      mode = "0400";
    };

    sops.secrets."github_token" = {
      owner = config.users.users.${cfg.username}.name;
      mode = "0400";
    };

    sops.secrets."openrouter_code_agent" = {
      owner = config.users.users.${cfg.username}.name;
      mode = "0400";
    };

    sops.secrets."openrouter_autocomplete" = {
      owner = config.users.users.${cfg.username}.name;
      mode = "0400";
    };

    sops.secrets."openrouter_terminal" = {
      owner = config.users.users.${cfg.username}.name;
      mode = "0400";
    };

    sops.secrets."openrouter_commit" = {
      owner = config.users.users.${cfg.username}.name;
      mode = "0400";
    };
  };
}
