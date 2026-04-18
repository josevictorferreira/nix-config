{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-erlang-interop";
  description = "Best practices for using Erlang and Elixir libraries within Gleam projects.";
  prompt = ''
    # Gleam Erlang Interop

    ## FFI with Erlang
    - Use `@external` attribute to call Erlang functions directly.
    - Map Erlang types to Gleam types carefully, especially for atoms and tuples.
    - Handle Erlang exceptions by wrapping calls in `try`/`catch` blocks.

    ## Using Elixir Libraries
    - Add Elixir libraries to your `mix.exs` or `rebar.config` dependencies.
    - Use `:application.ensure_all_started/1` to start Elixir applications.
    - Convert between Elixir structs and Gleam types at the boundary.

    ## BEAM Ecosystem Integration
    - Leverage Erlang/OTP behaviors like GenServer and Supervisor.
    - Use `erlang:spawn` and `erlang:send` for message passing.
    - Be aware of atom table limits when creating dynamic atoms.

    ## Type Safety
    - Create wrapper modules that provide Gleam-friendly APIs around Erlang libraries.
    - Use opaque types to hide implementation details.
    - Document expected Erlang return values thoroughly.
  '';
}
