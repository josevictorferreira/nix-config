# Aspect: roles-ai-development
# AI tooling comes from the zeh-ai-tooling flake input: skills, agents,
# commands, rules, MCP servers, plugins and the coding-agent installs
# (claude-code, opencode, pi, gemini, command-code, hermes-agent) plus rtk,
# lsp-mcp and the prompt scripts. This aspect imports it, picks what to
# enable, and maps its outputs (zeh.ai.home / zeh.ai.wrappers) onto jvf.home
# and jvf.wrappers.
_:
let
  mkModule =
    { isDarwin }:
    { config, inputs, ... }:
    let
      inherit (config.jvf.core) username;
    in
    {
      imports = [
        inputs.zeh-ai-tooling.modules.${if isDarwin then "darwin" else "nixos"}.default
      ];

      config = {
        zeh.ai = {
          inherit username;

          # Pi reads its provider keys from these files at runtime (`!cat`).
          secrets = {
            omniroute_api_key = config.sops.secrets.omniroute_api_key.path;
            velox_api_key = config.sops.secrets.velox_api_key.path;
            z_ai_api_key = config.sops.secrets.z_ai_api_key.path;
          };

          harnesses = {
            claude-code.enable = true;
            opencode.enable = true;
            pi.enable = true;
            gemini.enable = true;
            command-code.enable = true;
            hermes-agent.enable = true;

            # Claude Code settings (YOLO mode — bypass all permission prompts)
            claude-code.settings = {
              permissions = {
                defaultMode = "bypassPermissions";
              };
              attribution = {
                commit = "";
                pr = "";
              };
            };
          };

          tools = {
            rtk.enable = true;
            lsp-mcp.enable = true;
            prompt-enhancer.enable = true;
            rules-enforcer.enable = true;
          };

          mcp = {
            chrome-devtools.enable = true;
            jira.enable = true;
            grafana.enable = false;
            grafana-work.enable = false;
          };
        };

        # Consumer glue: zeh-ai-tooling outputs -> this config's home/wrapper machinery.
        jvf.home.users.${username}.items = config.zeh.ai.home;
        jvf.wrappers.users.${username}.programs = config.zeh.ai.wrappers;
        # gemini reads GEMINI_API_KEY from the secret environment.
        jvf.secrets.environment.keys.gemini_api_key = true;
      };
    };
in
{
  flake.modules.nixos.roles-ai-development = mkModule { isDarwin = false; };
  flake.modules.darwin.roles-ai-development = mkModule { isDarwin = true; };
}
