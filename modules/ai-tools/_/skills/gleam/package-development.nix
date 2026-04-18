{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-package-development";
  description = "Best practices for creating and publishing Gleam libraries and packages.";
  prompt = ''
    # Gleam Package Development

    ## Project Structure
    - Follow standard Gleam project layout with `src/`, `test/`, and `gleam.toml`.
    - Use clear module naming that reflects the package's purpose.
    - Keep the public API surface small and well-documented.

    ## gleam.toml
    - Fill in all metadata: `name`, `version`, `description`, `licences`.
    - Use semantic versioning. Start at `1.0.0` when stable.
    - Specify dependency versions with care using `~>` for compatible ranges.

    ## API Design
    - Design for composability. Functions should be small and pure.
    - Use opaque types to hide implementation details.
    - Provide sensible defaults via `new` or `default` functions.

    ## Documentation
    - Document all public functions with `@doc` comments.
    - Include examples in documentation.
    - Write a comprehensive `README.md` with usage examples.

    ## Testing
    - Use `gleeunit` for unit testing.
    - Aim for high test coverage, especially for public APIs.
    - Test edge cases and error conditions.

    ## Publishing to Hex
    - Run `gleam publish` to publish to Hex.pm.
    - Ensure `gleam.toml` metadata is complete before publishing.
    - Tag releases in git with the version number.

    ## Maintenance
    - Respond to issues and pull requests promptly.
    - Maintain a `CHANGELOG.md`.
    - Update dependencies regularly and test against new Gleam versions.
  '';
}
