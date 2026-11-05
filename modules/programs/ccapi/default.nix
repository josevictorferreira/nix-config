# Aspect: programs-ccapi
# `ccapi` - a second Claude Code entrypoint aimed at a third-party Anthropic-compatible
# proxy. The wrapper exports ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN (both read at
# runtime from sops, never stored in the nix store) and then execs the regular `claude`
# binary from PATH. The normal `claude` login is left completely untouched.
_:
let
  ccapiModule =
    { config, lib, pkgs, ... }:
    let
      cfg = config.jvf.programs.ccapi;
    in
    {
      options.jvf.programs.ccapi = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the ccapi wrapper.";
        };
      };

      config = {
        # Owned by the user so the wrapper can `cat` them at runtime.
        # Deliberately NOT registered in jvf.secrets.environment.keys:
        # that would export ANTHROPIC_* to every shell and leak these
        # credentials into the regular `claude` too.
        sops.secrets.ccapi_base_url.owner = cfg.username;
        sops.secrets.ccapi_auth_token.owner = cfg.username;

        jvf.wrappers.users.${cfg.username}.programs.ccapi.command =
          "${lib.getExe (pkgs.writeShellScriptBin "ccapi" ''
            set -euo pipefail
            export ANTHROPIC_BASE_URL="$(cat ${config.sops.secrets.ccapi_base_url.path})"
            export ANTHROPIC_AUTH_TOKEN="$(cat ${config.sops.secrets.ccapi_auth_token.path})"
            exec claude "$@"
          '')}";
      };
    };
in
{
  flake.modules.nixos.programs-ccapi = ccapiModule;
  flake.modules.darwin.programs-ccapi = ccapiModule;
}
