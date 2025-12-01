{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./ethical-scraper.nix)
]
