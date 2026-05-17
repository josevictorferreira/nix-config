# Aspect: secrets-environment
# Global environment secrets management.
# Modules self-register their secret keys; this module handles sops wiring
# and shell exports.
{ ... }:
let
  mkConfig =
    _:
    { config, lib, ... }:
    let
      cfg = config.jvf.secrets.environment;
      keyList = lib.attrNames cfg.keys;
      secretLines = map (
        name: "export ${lib.toUpper name}=\"$(cat ${config.sops.secrets.${name}.path})\""
      ) keyList;
    in
    {
      options.jvf.secrets.environment = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for secret ownership";
        };

        keys = lib.mkOption {
          type = lib.types.attrsOf lib.types.bool;
          default = {
            # AI / API keys (cross-cutting, no single owner module)
            openrouter_api_key_terminal = true;
            openrouter_api_key_commit = true;
            openrouter_api_key_autocomplete = true;
            openrouter_api_key_code_agent = true;
            openrouter_api_key_benchmark = true;
            context7_api_key = true;
            hugging_face_api_key = true;
            huggingface_api_key = true;
            nvidia_api_key = true;
            command_code_api_key = true;
            civitai_api_key = true;
            google_generative_ai_api_key = true;
            z_ai_api_key = true;
            opencode_go_api_key = true;
            kimi_api_key = true;
            alibaba_coding_plan_api_key = true;
            inception_api_key = true;
            roboflow_api_key = true;
            # Homelab / infra
            homelab_postgres_username = true;
            homelab_postgres_password = true;
            valoris_secret_key = true;
          };
          description =
            "Set of sops secret keys to expose as environment variables."
            + " Modules register their keys as attributes.";
        };
      };
      config = lib.mkMerge [
        {
          jvf.secrets.environment.keys = {
            # AI / API keys (cross-cutting, no single owner module)
            openrouter_api_key_terminal = true;
            openrouter_api_key_commit = true;
            openrouter_api_key_autocomplete = true;
            openrouter_api_key_code_agent = true;
            openrouter_api_key_benchmark = true;
            context7_api_key = true;
            hugging_face_api_key = true;
            huggingface_api_key = true;
            nvidia_api_key = true;
            command_code_api_key = true;
            civitai_api_key = true;
            google_generative_ai_api_key = true;
            z_ai_api_key = true;
            opencode_go_api_key = true;
            kimi_api_key = true;
            alibaba_coding_plan_api_key = true;
            inception_api_key = true;
            roboflow_api_key = true;
            # Homelab / infra
            homelab_postgres_username = true;
            homelab_postgres_password = true;
            valoris_secret_key = true;
          };
        }
        (lib.mkIf (keyList != [ ]) (
          lib.mkMerge [
            {
              sops.secrets = lib.listToAttrs (
                map (name: {
                  inherit name;
                  value = {
                    owner = cfg.username;
                  };
                }) keyList
              );
            }
            {
              programs.zsh.interactiveShellInit = lib.mkAfter (lib.concatStringsSep "\n" secretLines);
              programs.bash.interactiveShellInit = lib.mkAfter (lib.concatStringsSep "\n" secretLines);
            }
          ]
        ))
      ];
    };
in
{
  flake.modules.nixos.secrets-environment = mkConfig { isDarwin = false; };
  flake.modules.darwin.secrets-environment = mkConfig { isDarwin = true; };
}
