{ lib
, pkgs
, config
, ...
}:

{
  # Test that all required packages are available
  assertions = [
    {
      assertion = config.jvf.programs.zsh.enable -> pkgs ? zsh;
      message = "zsh package must be available";
    }
    {
      assertion = config.jvf.programs.zsh.features.aiCommit -> config.sops.secrets ? "openrouter_commit";
      message = "AI commit feature requires openrouter_commit secret";
    }
  ];
}
