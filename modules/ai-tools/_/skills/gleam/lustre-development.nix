{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
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
  name = "gleam-lustre-development";
  description = "Best practices for developing SPAs and interactive web applications using the Lustre framework.";
  prompt = ''
    # Gleam Lustre Development

    ## Model-Update-View Architecture
    - **Model**: Define your application state as a Gleam type.
    - **Update**: Handle messages to transform the model. Use pure functions.
    - **View**: Render HTML based on the current model. Use `lustre/element` functions.

    ## Components
    - Break your UI into reusable components.
    - Each component has its own Model, Update, View, and optional `init`/`on_mount`.
    - Communicate between components via messages.

    ## Effects
    - Use `lustre/effect` for side effects like HTTP requests, timers, and DOM manipulation.
    - Effects are pure descriptions of side effects that the runtime executes.
    - Chain effects with `effect.batch` or `effect.map`.
    - Use `lustre.application` (not `lustre.simple`) when update logic must run HTTP, timers, storage, clipboard, or other effects.
    - When serving compiled Lustre JavaScript from HTML, import the exported `main` and call `main()` explicitly; loading the module alone can leave the app root empty.

    ## Routing
    - Use `lustre/router` for client-side routing.
    - Define routes as a custom type and match on the URL.
    - Handle browser history with `lustre/navigation`.

    ## Styling
    - Use inline styles with `lustre/attribute.style` for simple cases.
    - For complex styling, consider CSS-in-Gleam or external CSS files.
    - Use CSS custom properties for theming.

    ## Testing
    - Test update functions with pure unit tests.
    - Use `lustre/testing` for testing view rendering.
    - Mock effects in tests by inspecting the returned effect value.
  '';
}
