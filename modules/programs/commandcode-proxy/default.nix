# Aspect: programs-commandcode-proxy
# Local OpenAI Chat Completions-compatible proxy for Command Code.
# Lets opencode (and any OpenAI-compatible client) reach CC through
# `@ai-sdk/openai-compatible` by pointing baseURL at http://127.0.0.1:<port>/v1.
# Runs as a systemd user service (NixOS) or launchd user agent (Darwin).
{ ... }:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.commandcode-proxy;
      pkg = pkgs.callPackage ./_/package.nix { };
      args = "-bind ${cfg.bind} -port ${toString cfg.port}";
    in
    {
      options.jvf.programs.commandcode-proxy = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "User the proxy service runs as.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 18080;
          description = "Port the proxy listens on.";
        };
        bind = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Bind address. Loopback by default — CC auth never leaves the box.";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.commandcode-proxy = {
          packages = [ pkg ];
        };
      }
      // (
        if isDarwin then
          {
            launchd.user.agents.commandcode-proxy = {
              serviceConfig = {
                ProgramArguments = [
                  "${pkg}/bin/commandcode-proxy"
                  "-bind"
                  cfg.bind
                  "-port"
                  (toString cfg.port)
                ];
                KeepAlive = true;
                RunAtLoad = true;
                StandardOutPath = "/tmp/commandcode-proxy.out.log";
                StandardErrorPath = "/tmp/commandcode-proxy.err.log";
              };
            };
          }
        else
          {
            systemd.user.services.commandcode-proxy = {
              description = "Command Code OpenAI-compatible proxy";
              wantedBy = [ "default.target" ];
              serviceConfig = {
                ExecStart = "${pkg}/bin/commandcode-proxy ${args}";
                Restart = "on-failure";
                RestartSec = "5s";
              };
            };
          }
      );
    };
in
{
  flake.modules.nixos.programs-commandcode-proxy = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-commandcode-proxy = mkConfig { isDarwin = true; };
}
