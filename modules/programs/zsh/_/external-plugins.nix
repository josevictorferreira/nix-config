# external-plugins.nix - External ZSH plugins from GitHub
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.jvf.programs.zsh;

  mkPlugin =
    { name, src }:
    pkgs.stdenv.mkDerivation {
      inherit name src;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out
        cp -r * $out
      '';
    };

  plugins = [
    (mkPlugin {
      name = "zsh-fast-syntax-highlighting";
      src = pkgs.fetchFromGitHub {
        owner = "zdharma-continuum";
        repo = "fast-syntax-highlighting";
        rev = "v1.55";
        sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
      };
    })
    (mkPlugin {
      name = "zsh-autosuggestions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-autosuggestions";
        rev = "v0.7.0";
        sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
      };
    })
    (mkPlugin {
      name = "zsh-completions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-completions";
        rev = "0.35.0";
        sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg=";
      };
    })
    (mkPlugin {
      name = "fzf-tab";
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "v1.1.2";
        sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
      };
    })
    (mkPlugin {
      name = "zsh-history-substring-search";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-history-substring-search";
        rev = "v1.1.0";
        sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
      };
    })
    (mkPlugin {
      name = "zsh-vi-mode";
      src = pkgs.fetchFromGitHub {
        owner = "jeffreytse";
        repo = "zsh-vi-mode";
        rev = "v0.11.0";
        sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
      };
    })
  ];
in
{
  environment.systemPackages = plugins;

  programs.zsh.interactiveShellInit = lib.mkIf cfg.setAsDefaultShell ''
    # Source external plugins (with existence checks for GC resilience)
    if [ -f ${builtins.elemAt plugins 0}/fast-syntax-highlighting.plugin.zsh ]; then
      source ${builtins.elemAt plugins 0}/fast-syntax-highlighting.plugin.zsh
    fi
    if [ -f ${builtins.elemAt plugins 1}/zsh-autosuggestions.zsh ]; then
      source ${builtins.elemAt plugins 1}/zsh-autosuggestions.zsh
    fi
    if [ -f ${builtins.elemAt plugins 2}/zsh-completions.plugin.zsh ]; then
      source ${builtins.elemAt plugins 2}/zsh-completions.plugin.zsh
    fi
    if [ -f ${builtins.elemAt plugins 3}/fzf-tab.plugin.zsh ]; then
      source ${builtins.elemAt plugins 3}/fzf-tab.plugin.zsh
    fi
    if [ -f ${builtins.elemAt plugins 4}/zsh-history-substring-search.zsh ]; then
      source ${builtins.elemAt plugins 4}/zsh-history-substring-search.zsh
    fi
    if [ -f ${builtins.elemAt plugins 5}/zsh-vi-mode.plugin.zsh ]; then
      source ${builtins.elemAt plugins 5}/zsh-vi-mode.plugin.zsh
    fi
  '';
}
