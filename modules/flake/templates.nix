# Flake templates — project scaffolds.
# Moved here from flake.nix to keep the entrypoint minimal.
_:
{
  flake.templates = {
    sandbox-postgres-ruby = {
      path = ./../../templates/sandbox-postgres-ruby;
      description = "Sandbox with PostgreSQL 16 and Ruby 3.3";
    };
    sandbox-postgres-django = {
      path = ./../../templates/sandbox-postgres-django;
      description = "Sandbox with PostgreSQL (PostGIS/TimescaleDB) and Django";
    };
    frontend-bun-vite = {
      path = ./../../templates/frontend-bun-vite;
      description = "Frontend template using Bun and Vite.js";
    };
  };
}
