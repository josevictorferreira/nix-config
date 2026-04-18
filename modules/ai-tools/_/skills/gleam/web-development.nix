{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-web-development";
  description = "Building web applications and APIs with Gleam using Wisp, Mist, and related tools.";
  prompt = ''
    # Gleam Web Development

    ## Wisp
    - Wisp is a web framework for Gleam running on the Erlang VM.
    - Define routes using pattern matching on the request path and method.
    - Use middleware for cross-cutting concerns like logging and CORS.

    ## Mist
    - Mist is a lightweight HTTP server for Gleam.
    - Use it when you need more control than Wisp provides.
    - Handle WebSocket connections with `mist/websocket`.

    ## Routing
    - Define routes as a custom type and match in a central handler.
    - Use path parameters with pattern matching.
    - Extract query parameters with `wisp/query_string`.

    ## Request Handling
    - Parse JSON bodies with `gleam_json`.
    - Handle form data with `wisp/form`.
    - Validate input early and return 400 Bad Request for invalid data.

    ## Responses
    - Return appropriate HTTP status codes.
    - Use `wisp/response` helpers for common responses.
    - Set content-type headers correctly for JSON, HTML, etc.

    ## Middleware
    - Create reusable middleware for auth, logging, rate limiting.
    - Compose middleware with function composition.
    - Apply middleware in the correct order (auth before route handling).

    ## Database
    - Use `gleam_pgo` or `gleam_sqlight` for database access.
    - Use connection pooling for production applications.
    - Write migration scripts and version your schema.

    ## Testing
    - Test handlers by creating mock requests.
    - Use `wisp/testing` helpers for HTTP assertions.
    - Test middleware in isolation.
  '';
}
