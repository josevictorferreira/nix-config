{
  pkgs,
  config,
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
in
{
  plugins = cfg.plugins;

  customPkgs = [
    # Syntax highlighting
    (mkPlugin {
      name = "zsh-fast-syntax-highlighting";
      src = pkgs.fetchFromGitHub {
        owner = "zdharma-continuum";
        repo = "fast-syntax-highlighting";
        rev = "v1.55";
        sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
      };
    })

    # Autosuggestions
    (mkPlugin {
      name = "zsh-autosuggestions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-autosuggestions";
        rev = "v0.7.0";
        sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
      };
    })

    # Completions
    (mkPlugin {
      name = "zsh-completions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-completions";
        rev = "0.35.0";
        sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg=";
      };
    })

    # FZF tab completion
    (mkPlugin {
      name = "fzf-tab";
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "v1.1.2";
        sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
      };
    })

    # History substring search
    (mkPlugin {
      name = "zsh-history-substring-search";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-history-substring-search";
        rev = "v1.1.0";
        sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
      };
    })
  ]
  ++ [
    # Vi mode
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
}
