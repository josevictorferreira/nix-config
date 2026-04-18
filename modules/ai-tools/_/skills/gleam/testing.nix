{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-testing";
  description = "Testing strategies and patterns for Gleam applications using gleeunit and other tools.";
  prompt = ''
    # Gleam Testing

    ## gleeunit
    - Use `gleeunit` as the primary testing framework.
    - Tests are functions in `test/` directory with names ending in `_test`.
    - Use `let assert` for simple assertions.

    ## Test Organization
    - Mirror your `src/` directory structure in `test/`.
    - Group related tests in descriptive modules.
    - Use `describe` blocks to group tests by functionality.

    ## Assertions
    - `let assert Ok(value) = result` to unwrap Results.
    - `let assert Error(err) = result` to assert errors.
    - Use `should.equal` and `should.be_true`/`should.be_false` for clarity.

    ## Property-Based Testing
    - Use `gleeunit` with property-based testing libraries.
    - Generate random inputs to test invariants.
    - Shrink failing cases to minimal examples.

    ## Testing Effects
    - For pure functions, test inputs and outputs directly.
    - For effectful code, structure to allow injecting test doubles.
    - Use `process` module testing helpers for actor tests.

    ## Test Coverage
    - Aim for high coverage but prioritize testing behavior over lines.
    - Test edge cases: empty inputs, boundary values, error conditions.
    - Don't test implementation details; test observable behavior.

    ## Continuous Integration
    - Run tests on every commit with GitHub Actions or similar.
    - Test against multiple Gleam versions if maintaining a library.
    - Use `gleam test` in CI scripts.
  '';
}
