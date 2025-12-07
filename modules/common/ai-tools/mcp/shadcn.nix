{ pkgs }:

{
  shadcn = {
    opencode = {
      type = "local";
      enabled = true;
      command = [
        "${pkgs.bun}/bin/bunx"
        "--bun"
        "shadcn@latest"
        "mcp"
      ];
    };
  };
}
