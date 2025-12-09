{ ... }:
{
  imports = [
    ./add-and-format.nix
    ./review.nix
    ./commit-msg.nix
    ./commit-changes.nix
  ];

  config = {
    # no-op; commands are pure data modules
  };
}
