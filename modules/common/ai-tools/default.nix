{
  ...
}:

{
  imports = [
    (import ./rules.nix)
    (import ./scripts)
    (import ./mcp)
    (import ./agents)
    (import ./commands)
    (import ./skills)
  ];
}
