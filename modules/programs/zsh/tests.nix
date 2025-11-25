{
  pkgs,
  config,
  ...
}:

{
  # Test that all required packages are available
  assertions = [
    {
      assertion = config.jvf.programs.zsh.enable -> pkgs ? zsh;
      message = "zsh package must be available";
    }
  ];
}
