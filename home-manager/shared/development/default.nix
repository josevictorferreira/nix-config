{
  pkgs,
  ...
}:
{
  imports = [
    ./formatters.nix
    ./languages.nix
    ./lsp-servers.nix
  ];

  home = {
    packages = with pkgs; [
      claude-code
    ];
  };
}
