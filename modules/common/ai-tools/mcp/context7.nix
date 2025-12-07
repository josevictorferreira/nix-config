{ lib, pkgs, system }:

{
  context7 = {
    opencode = {
      type = "remote";
      enabled = true;
      url = "https://mcp.context7.com/mcp";
      headers = {
        CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      };
    };
  };
}
