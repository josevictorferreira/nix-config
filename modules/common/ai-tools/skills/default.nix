{ ... }:

{
  imports = [
    ./general/auditing-security.nix
    ./general/creating-skills.nix
    ./general/research-tools.nix.nix
    ./container/developing-containers.nix
    ./nix/creating-nix-modules.nix
    ./nix/managing-flakes.nix
    ./nix/writing-nix-code.nix
    ./python/pythonic-scraping-websites.nix
    ./ruby/developing-rails-background-jobs.nix
    ./ruby/developing-rails-event-store.nix
    ./ruby/developing-rails-scrapers.nix
    ./ruby/developing-rspec-tests.nix
    ./ruby/fixing-rubocop-offenses.nix
  ];
}
