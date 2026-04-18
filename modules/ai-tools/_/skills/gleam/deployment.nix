{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" "Bash" ];
  name = "gleam-deployment";
  description = "Guides on deploying Gleam applications to various platforms like Fly.io and Docker.";
  prompt = ''
    # Gleam Deployment

    When deploying Gleam applications, consider the following platforms and strategies:

    ## Fly.io
    - **Deployment Process**: Use `flyctl deploy` to deploy your Gleam application. Ensure your `fly.toml` is configured correctly.
    - **Environment Variables**: Set secrets using `flyctl secrets set KEY=VALUE`.
    - **Database**: For PostgreSQL, use `flyctl postgres create` and attach it to your app.
    - **Monitoring**: Use `flyctl logs` to view application logs and `flyctl status` to check the status of your app.

    ## Docker
    - **Dockerfile**: Create a Dockerfile that uses the official Gleam image. Ensure you copy your `gleam.toml` and source code.
    - **Multi-stage Builds**: Use multi-stage builds to keep your final image small. Build in one stage and copy the binary to a smaller runtime image.
    - **Docker Compose**: For local development, use Docker Compose to spin up your app alongside databases or other services.

    ## General Tips
    - **Health Checks**: Configure health checks to ensure your application is running correctly.
    - **Logging**: Use structured logging to make it easier to parse logs in production.
    - **Scaling**: Consider horizontal scaling for stateless applications.
  '';
}
