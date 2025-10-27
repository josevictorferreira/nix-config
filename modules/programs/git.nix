{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.git;
  preCommit = pkgs.writeShellScript "pre-commit-secrets-check" ''
    #!/usr/bin/env bash
    set -euo pipefail
    fail=0
    for file in $(${pkgs.git}/bin/git diff --cached --name-only -- '*.enc.yaml' '*.enc.yml'); do
      if ! ${pkgs.yq}/bin/yq -e 'has("sops") and (.sops.mac // "" != "")' "$file" >/dev/null 2>&1; then
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
  options.programs.git = {
    enable = mkEnableOption (lib.mdDoc "Git version control system");

    package = mkOption {
      type = types.package;
      default = pkgs.git;
      defaultText = literalExpression "pkgs.git";
      description = lib.mdDoc "Git package to install";
    };

    userName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Jane Doe";
      description = lib.mdDoc ''
        The globally configured user name for Git. This is equivalent to
        setting the `user.name` option in the global Git configuration.
      '';
    };

    userEmail = mkOption {
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
          setting the `user.signingkey` option in the global Git configuration.
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
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          core = {
            editor = "nvim";
            autocrlf = "input";
          };
          push = {
            default = "simple";
          };
        }
      '';
      description = lib.mdDoc ''
        Additional configuration for Git. This is equivalent to setting
        arbitrary options in the global Git configuration.
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
        ignore file at {file}`/etc/git/ignore`.
      '';
    };

    lfs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to enable Git Large File Storage (LFS)";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (optionalAssertion (cfg.userName == null) ''
        programs.git.userName must be set when programs.git.enable = true
      '')
      (optionalAssertion (cfg.userEmail == null) ''
        programs.git.userEmail must be set when programs.git.enable = true
      '')
    ];

    environment.systemPackages = [ cfg.package ] ++ (optional cfg.lfs.enable pkgs.git-lfs);

    environment.etc."gitconfig".text = generators.toINI { } (
      (optionalAttrs (cfg.userName != null) { "user".name = cfg.userName; })
      // (optionalAttrs (cfg.userEmail != null) { "user".email = cfg.userEmail; })
      // (optionalAttrs (cfg.signing.key != null) { "user".signingkey = cfg.signing.key; })
      // (optionalAttrs cfg.signing.signByDefault { "commit".gpgsign = "true"; })
      // (optionalAttrs (cfg.aliases != { }) { alias = cfg.aliases; })
      // cfg.extraConfig
    );

    environment.etc."git/ignore".text = concatStringsSep "\n" cfg.ignores;

    system.activationScripts.git-lfs-setup = optionalString cfg.lfs.enable ''
      if [ ! -f /etc/profile.d/git-lfs.sh ]; then
        ${cfg.package}/bin/git lfs install --system
      fi
    '';

    xdg.configFile."git/hooks/pre-commit" = {
      source = preCommit;
      executable = true;
    };
  };
}
