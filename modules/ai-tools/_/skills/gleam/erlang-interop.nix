{
  lib,
  pkgs,
  isDarwin,
  npx,
  defaultBrowser,
  kebabToHuman,
  ...
}:
{
  allowed-tools = [
    "Read"
    "Grep"
    "Glob"
    "Write"
    "Edit"
    "Bash"
  ];
  name = "gleam-erlang-interop";
  description = "Best practices for using Erlang and Elixir libraries within Gleam projects.";
  prompt = ''
    # Gleam Erlang Interop

    ## Erlang FFI files (.erl in src/)
    - Place `.erl` files in `src/` alongside `.gleam` files. Gleam copies them to `build/dev/erlang/.../_gleam_artefacts/`.
    - Use `@external(erlang, "module_name", "function_name")` to call Erlang functions from Gleam.
    - Return `{ok, Value}` for success, `{error, Reason}` for failure to match Gleam's `Result` type.
    - Strings passed to Erlang are binaries. Use `binary_to_list(String)` for `httpc` headers, `iolist_to_binary` for error messages.
    - **After editing .erl files, do `rm -rf build && gleam build`.** Gleam's incremental build doesn't always detect changes, and stale build artifacts produce confusing syntax errors at lines that don't correspond to the source.

    ## HTTP calls from Erlang (httpc)
    - Start `inets` and `ssl` with `application:ensure_all_started(inets)`, `application:ensure_all_started(ssl)`.
    - Use `httpc:request(post, {Url, Headers, ContentType, Body}, [{timeout, 60000}], [{body_format, binary}])`.
    - Match `{ok, {{_, Status, _}, _Headers, ResponseBody}}` for responses.

    ## Using Erlang standard library
    - `crypto:strong_rand_bytes(N)` for random bytes via FFI (e.g., UUID generation). No need to add `gleam_crypto` as a direct dependency.
    - `erlang:system_time(second)` for wall-clock timestamps.
    - `os:getenv(binary_to_list(Name))` returns `false` when unset, not an empty string.

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
