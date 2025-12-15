{
  ...
}:

{
  imports = [
    (import ./lib.nix)
    (import ./rules.nix)
    (import ./scripts)
    (import ./mcp)
    (import ./agents)
    (import ./commands)
    (import ./skills)
  ];
}
