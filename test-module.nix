# Minimal test module for Darwin compatibility
{
  config,
  lib,
  pkgs,
  isDarwin,
  ...
}:

let
  cfg = config.jvf.test;
in
{
  options.jvf.test = {
    enable = lib.mkEnableOption "test module";
  };

  config = lib.mkIf cfg.enable {
    # Simple test that should work on both platforms
    environment.systemPackages = lib.mkIf (!isDarwin) [ pkgs.hello ];

    # Darwin-specific test
    launchd.agents = lib.mkIf isDarwin {
      "test-agent" = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "echo test"
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}
