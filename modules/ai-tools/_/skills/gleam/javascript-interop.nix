{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-javascript-interop";
  description = "Guidelines for integrating JavaScript code and NPM packages into Gleam projects.";
  prompt = ''
    # Gleam JavaScript Interop

    ## FFI with JavaScript
    - Use `@external(javascript, "module", "function")` to call JS functions.
    - Map JavaScript types to Gleam types carefully.
    - Handle `null`/`undefined` with Gleam's `Option` type.

    ## NPM Integration
    - Add dependencies to `package.json` as usual.
    - Use `import` in your `@external` declarations for ES modules.
    - For CommonJS, use `require` directly in the external implementation.

    ## Browser APIs
    - Wrap DOM APIs in Gleam functions for type safety.
    - Use `gleam_javascript` library for common JS interop patterns.
    - Handle callbacks and promises with Gleam's `Promise` type.

    ## Lustre Basics
    - Lustre is a framework for building web apps in Gleam.
    - Understand the Model-Update-View architecture.
    - Use `lustre` effects for side effects like HTTP requests.

    ## Type Safety
    - Create wrapper modules for JS libraries.
    - Use `dynamic` module for decoding unknown JS values.
    - Avoid `unsafe_coerce` unless absolutely necessary.
  '';
}
