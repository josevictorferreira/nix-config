{ ... }:
{
  imports = [
    ./frontend/ui-ux-architect.nix
    ./frontend/swiss-minimalist-designer.nix
    ./general/code-reviewer.nix
    ./general/documentation-writer.nix
    ./ruby/rails-builder.nix
    ./ruby/rails-linter.nix
    ./ruby/rails-orchestrator.nix
    ./ruby/rails-tester.nix
  ];
}
