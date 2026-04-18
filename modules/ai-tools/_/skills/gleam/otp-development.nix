{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-otp-development";
  description = "Guidelines for building robust concurrent applications using Gleam's OTP bindings.";
  prompt = ''
    # Gleam OTP Development

    ## Actors
    - Use `gleam/otp/actor` to create lightweight processes.
    - Define message types as custom Gleam types.
    - Handle messages in a recursive loop with tail-call optimization.

    ## Supervisors
    - Use `gleam/otp/supervisor` to build supervision trees.
    - Choose restart strategies: `one_for_one`, `one_for_all`, `rest_for_one`.
    - Set `max_restarts` and `max_seconds` to prevent restart loops.

    ## Fault Tolerance
    - Let it crash! Don't defensively code against all errors.
    - Use supervisors to restart failed processes.
    - Design your supervision tree so failures are contained.

    ## GenServer
    - Use `gleam/otp/gen_server` for stateful processes.
    - Implement `init`, `handle_call`, `handle_cast`, and `handle_info` callbacks.
    - Use `call` for synchronous requests and `cast` for asynchronous messages.

    ## Tasks
    - Use `gleam/otp/task` for one-off concurrent computations.
    - `await` tasks with timeouts to avoid blocking indefinitely.
    - Link tasks to the current process for error propagation.

    ## Best Practices
    - Keep actors small and focused on a single responsibility.
    - Use monitors when you need to observe but not supervise a process.
    - Test concurrent code with `gleam/otp/testing` helpers.
  '';
}
