# Aspect: programs-git
# Defines jvf.programs.git options and platform-specific git configuration.
# NixOS: enables programs.git + LFS via system module.
# Darwin: packages + wrappers only (no programs.git module).
_:
let
  mkGitOptions =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      inherit (lib)
        mkOption
        types
        literalExpression
        ;

      defaultExtraConfig = {
        core = {
          editor = "nvim";
          hooksPath = "/etc/git/hooks";
        };
        diff = {
          tool = "nvimdiff";
        };
        merge = {
          tool = "nvimdiff3";
        };
        mergetool = {
          prompt = false;
          keepBackup = false;
        };
        init = {
          defaultBranch = "main";
        };
        push = {
          autoSetupRemote = true;
          followTags = true;
        };
        pull = {
          rebase = true;
        };
        fetch = {
          prune = true;
          tags = true;
        };
      };
    in
    {
      options.jvf.programs.git = {
        package = mkOption {
          type = types.package;
          default = pkgs.git;
          defaultText = literalExpression "pkgs.git";
          description = lib.mdDoc "Git package to install";
        };

        username = mkOption {
          type = types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };

        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "Jane Doe";
          description = lib.mdDoc ''
            The globally configured user name for Git. This is equivalent to
            setting the `user.name` option in the global Git configuration.
          '';
        };

        email = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "jane.doe@example.org";
          description = lib.mdDoc ''
            The globally configured user email address for Git. This is equivalent to
            setting the `user.email` option in the global Git configuration.
          '';
        };

        signing = {
          key = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "key::id";
            description = lib.mdDoc ''
              The GPG key to use for signing commits. This is equivalent to
              setting the `user.signingkey` option in the global Git configuration.
            '';
          };

          signByDefault = mkOption {
            type = types.bool;
            default = false;
            description = lib.mdDoc ''
              Whether to sign commits by default. This is equivalent to
              setting the `commit.gpgsign` option in the global Git configuration.
            '';
          };
        };

        aliases = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = literalExpression ''
            {
              st = "status";
              co = "checkout";
              br = "branch";
              ci = "commit";
              dc = "diff --cached";
            }
          '';
          description = lib.mdDoc ''
            Aliases for Git commands. This is equivalent to setting the
            `[alias]` section in the global Git configuration.
          '';
        };

        extraConfig = mkOption {
          type = types.attrsOf (
            types.attrsOf (
              types.oneOf [
                lib.types.str
                lib.types.bool
                lib.types.attrs
              ]
            )
          );
          default = defaultExtraConfig;
          example = literalExpression ''
            {
              core.autocrlf = "input";
              push.default = "simple";
            }
          '';
          description = lib.mdDoc ''
            Additional configuration for Git. This is equivalent to setting
            arbitrary options in the global Git configuration. Defaults include
            developer-friendly settings (nvim editor, difftastic diff, SSH for GitHub,
            auto-setup remote pushes, rebase on pull, etc.) matching standard Home Manager setup.
          '';
        };

        ignores = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = literalExpression ''
            [
              "*.log"
              ".DS_Store"
              "result"
            ]
          '';
          description = lib.mdDoc ''
            Additional patterns to ignore. These are added to the global
            ignore file at `/etc/git/ignore`.
          '';
        };

        lfs = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = lib.mdDoc "Whether to enable Git Large File Storage (LFS)";
          };
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      inherit (lib)
        optional
        optionalAttrs
        concatStringsSep
        generators
        ;

      cfg = config.jvf.programs.git;

      preCommit = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        export PATH="${
          pkgs.lib.makeBinPath [
            pkgs.git
            pkgs.yq
          ]
        }:$PATH"
        fail=0
        for file in $(git diff --cached --name-only -- '*.enc.yaml' '*.enc.yml'); do
          if ! yq -e 'has("sops") and (.sops.mac // "" != "")' "$file" >/dev/null 2>&1; then
            echo "❌ ERROR: $file is not encrypted with sops!"
            fail=1
          fi
        done
        if [ $fail -eq 1 ]; then
          echo "Commit aborted. Please encrypt files with: make emanifests"
          exit 1
        fi
      '';
    in
    {
      imports = [ mkGitOptions ];

      config = {
        assertions = [
          {
            assertion = cfg.name != null;
            message = "jvf.programs.git.name must be set";
          }
          {
            assertion = cfg.email != null;
            message = "jvf.programs.git.email must be set";
          }
        ];

        environment.systemPackages = [
          cfg.package
          pkgs.yq
          pkgs.difftastic
          pkgs.gitleaks
        ]
        ++ optional cfg.lfs.enable pkgs.git-lfs;

        jvf.home.users.${cfg.username} = {
          items.".config/git/config" = {
            kind = "file";
            mode = "copy";
            text =
              generators.toINI { }
                (
                  (optionalAttrs (cfg.name != null) { user.name = cfg.name; })
                    // (optionalAttrs (cfg.email != null) { user.email = cfg.email; })
                    // (optionalAttrs (cfg.signing.key != null) { user.signingkey = cfg.signing.key; })
                    // (optionalAttrs cfg.signing.signByDefault { commit.gpgsign = "true"; })
                    // (optionalAttrs (cfg.aliases != { }) { alias = cfg.aliases; })
                    // cfg.extraConfig
                )
              + ''
                [diff]
                  external = ${pkgs.difftastic}/bin/difft
              '';
          };
          items.".gitignore" = {
            kind = "file";
            mode = "copy";
            text = concatStringsSep "\n" cfg.ignores;
          };
          items.".git/hooks/pre-commit" = {
            kind = "file";
            mode = "copy";
            text = toString preCommit;
          };
        }
        // lib.optionalAttrs (!isDarwin) { };
      }
      // lib.optionalAttrs (!isDarwin) {
        programs.git.enable = true;
        programs.git.lfs.enable = cfg.lfs.enable;
      };
    };
in
{
  flake.modules.nixos.programs-git = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-git = mkConfig { isDarwin = true; };
}
